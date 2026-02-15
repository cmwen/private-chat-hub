package com.cmwen.private_chat_hub

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File
import java.lang.reflect.Modifier

/**
 * LiteRT-LM Plugin for Flutter
 *
 * This plugin provides on-device LLM inference capabilities using Google's LiteRT-LM.
 * It handles model loading, text generation, and resource management.
 *
 * This plugin now includes a runtime bridge that attempts to bind to LiteRT-LM
 * classes via reflection. This allows iterative implementation without forcing
 * compile-time dependency coupling during early integration.
 */
class LiteRTPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val runtimeBridge: LiteRtRuntimeBridge = ReflectionLiteRtRuntimeBridge()
    private var runtimeSession: LiteRtRuntimeSession? = null

    // Coroutine scope for async operations
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Engine state
    private var isEngineLoaded = false
    private var currentModelId: String? = null
    private var currentModelPath: String? = null
    private var currentBackend: String = "cpu"

    // Generation state
    private var isGenerating = false
    private var generationJob: Job? = null

    // Performance metrics
    private var lastLoadTimeMs: Long = 0
    private var lastPrefillTokensPerSec: Double = 0.0
    private var lastDecodeTokensPerSec: Double = 0.0

    companion object {
        private const val TAG = "LiteRTPlugin"
        private const val METHOD_CHANNEL = "com.cmwen.private_chat_hub/litert"
        private const val EVENT_CHANNEL = "com.cmwen.private_chat_hub/litert_stream"
        private const val MIN_ANDROID_API = Build.VERSION_CODES.N
        private const val MIN_TOTAL_MEMORY_BYTES = 3L * 1024 * 1024 * 1024 // 3 GB
        private const val RECOMMENDED_TOTAL_MEMORY_BYTES = 6L * 1024 * 1024 * 1024 // 6 GB
        private const val MIN_AVAILABLE_MEMORY_BYTES = 1024L * 1024 * 1024 // 1 GB

        // Supported backends
        const val BACKEND_CPU = "cpu"
        const val BACKEND_GPU = "gpu"
        const val BACKEND_NPU = "npu"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        log("Plugin attached to Flutter engine")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        coroutineScope.cancel()

        // Clean up resources
        unloadModelInternal()

        log("Plugin detached from Flutter engine")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> {
                result.success(checkAvailability())
            }

            "loadModel" -> {
                val modelPath = call.argument<String>("modelPath")
                val backend = call.argument<String>("backend") ?: BACKEND_GPU

                if (modelPath == null) {
                    result.error("INVALID_ARGUMENT", "modelPath is required", null)
                    return
                }

                loadModel(modelPath, backend, result)
            }

            "unloadModel" -> {
                unloadModel(result)
            }

            "generateText" -> {
                val prompt = call.argument<String>("prompt")
                val temperature = call.argument<Double>("temperature") ?: 0.7
                val maxTokens = call.argument<Int>("maxTokens")
                val topK = call.argument<Int>("topK") ?: 40
                val topP = call.argument<Double>("topP") ?: 0.9
                val repetitionPenalty = call.argument<Double>("repetitionPenalty") ?: 1.0

                if (prompt == null) {
                    result.error("INVALID_ARGUMENT", "prompt is required", null)
                    return
                }

                generateText(
                    prompt = prompt,
                    temperature = temperature,
                    maxTokens = maxTokens,
                    topK = topK,
                    topP = topP,
                    repetitionPenalty = repetitionPenalty,
                    result = result
                )
            }

            "startGeneration" -> {
                val prompt = call.argument<String>("prompt")
                val temperature = call.argument<Double>("temperature") ?: 0.7
                val maxTokens = call.argument<Int>("maxTokens")
                val topK = call.argument<Int>("topK") ?: 40
                val topP = call.argument<Double>("topP") ?: 0.9
                val repetitionPenalty = call.argument<Double>("repetitionPenalty") ?: 1.0

                if (prompt == null) {
                    result.error("INVALID_ARGUMENT", "prompt is required", null)
                    return
                }

                startStreamingGeneration(
                    prompt = prompt,
                    temperature = temperature,
                    maxTokens = maxTokens,
                    topK = topK,
                    topP = topP,
                    repetitionPenalty = repetitionPenalty
                )
                result.success(null)
            }

            "cancelGeneration" -> {
                cancelGeneration()
                result.success(null)
            }

            "isModelLoaded" -> {
                result.success(isEngineLoaded)
            }

            "getCurrentModelId" -> {
                result.success(currentModelId)
            }

            "getDeviceCapabilities" -> {
                result.success(getDeviceCapabilities())
            }

            "getReadinessReport" -> {
                result.success(getReadinessReport())
            }

            "getMemoryInfo" -> {
                result.success(getMemoryInfo())
            }

            "getBenchmark" -> {
                result.success(getBenchmarkResults())
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    // ========================================================================
    // EventChannel.StreamHandler implementation
    // ========================================================================

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        log("Event stream listener attached")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        cancelGeneration()
        log("Event stream listener cancelled")
    }

    // ========================================================================
    // Core functionality
    // ========================================================================

    private fun checkAvailability(): Boolean {
        val report = getReadinessReport()
        return report["isSupported"] as? Boolean ?: false
    }

    private fun loadModel(modelPath: String, backend: String, result: MethodChannel.Result) {
        coroutineScope.launch(Dispatchers.IO) {
            try {
                log("Loading model from: $modelPath with backend: $backend")

                val startTime = System.currentTimeMillis()

                // Verify model file exists
                val modelFile = File(modelPath)
                if (!modelFile.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("FILE_NOT_FOUND", "Model file not found: $modelPath", null)
                    }
                    return@launch
                }

                // Check available memory
                val memInfo = getMemoryInfo()
                val availableMemory = memInfo["availableMemory"] ?: 0L
                val modelSize = modelFile.length()

                if (availableMemory < modelSize * 2) {
                    log("Warning: Low memory. Available: $availableMemory, Model size: $modelSize")
                }

                // Unload any existing model/session before creating a new one
                unloadModelInternal()

                if (!runtimeBridge.isRuntimeAvailable()) {
                    withContext(Dispatchers.Main) {
                        result.error(
                            "SDK_UNAVAILABLE",
                            runtimeBridge.getRuntimeUnavailableReason(),
                            null
                        )
                    }
                    return@launch
                }

                runtimeSession = runtimeBridge.openSession(
                    modelPath = modelPath,
                    backend = backend
                )

                lastLoadTimeMs = System.currentTimeMillis() - startTime
                isEngineLoaded = true
                currentModelPath = modelPath
                currentModelId = modelFile.nameWithoutExtension
                currentBackend = backend

                log("Model loaded successfully in ${lastLoadTimeMs}ms")

                withContext(Dispatchers.Main) {
                    result.success(true)
                }

            } catch (e: Exception) {
                log("Error loading model: ${e.message}")
                withContext(Dispatchers.Main) {
                    result.error("LOAD_ERROR", "Failed to load model: ${e.message}", null)
                }
            }
        }
    }

    private fun unloadModel(result: MethodChannel.Result) {
        try {
            unloadModelInternal()
            result.success(true)
        } catch (e: Exception) {
            result.error("UNLOAD_ERROR", "Failed to unload model: ${e.message}", null)
        }
    }

    private fun unloadModelInternal() {
        // Cancel any ongoing generation
        cancelGeneration()

        try {
            runtimeSession?.close()
        } catch (e: Exception) {
            log("Error while closing runtime session: ${e.message}")
        }
        runtimeSession = null

        isEngineLoaded = false
        currentModelId = null
        currentModelPath = null

        // Request garbage collection to free memory
        System.gc()

        log("Model unloaded")
    }

    private fun generateText(
        prompt: String,
        temperature: Double,
        maxTokens: Int?,
        topK: Int,
        topP: Double,
        repetitionPenalty: Double,
        result: MethodChannel.Result
    ) {
        if (!isEngineLoaded) {
            result.error("MODEL_NOT_LOADED", "No model is currently loaded", null)
            return
        }

        coroutineScope.launch(Dispatchers.IO) {
            try {
                isGenerating = true
                log("Generating text for prompt: ${prompt.take(50)}...")
                val session = runtimeSession
                if (session == null) {
                    withContext(Dispatchers.Main) {
                        result.error("MODEL_NOT_LOADED", "No active LiteRT session", null)
                    }
                    return@launch
                }

                val responseText = session.generateText(
                    prompt = prompt,
                    options = LiteRtGenerationOptions(
                        temperature = temperature,
                        maxTokens = maxTokens,
                        topK = topK,
                        topP = topP,
                        repetitionPenalty = repetitionPenalty,
                    )
                )

                withContext(Dispatchers.Main) {
                    result.success(responseText)
                }

            } catch (e: Exception) {
                log("Error generating text: ${e.message}")
                withContext(Dispatchers.Main) {
                    result.error("GENERATION_ERROR", "Failed to generate text: ${e.message}", null)
                }
            } finally {
                isGenerating = false
            }
        }
    }

    private fun startStreamingGeneration(
        prompt: String,
        temperature: Double,
        maxTokens: Int?,
        topK: Int,
        topP: Double,
        repetitionPenalty: Double,
    ) {
        if (!isEngineLoaded) {
            sendEventError("MODEL_NOT_LOADED", "No model is currently loaded")
            return
        }

        if (isGenerating) {
            sendEventError("GENERATION_IN_PROGRESS", "A generation is already in progress")
            return
        }

        generationJob = coroutineScope.launch(Dispatchers.IO) {
            try {
                isGenerating = true
                log("Starting streaming generation for prompt: ${prompt.take(50)}...")
                val session = runtimeSession
                if (session == null) {
                    sendEventError("MODEL_NOT_LOADED", "No active LiteRT session")
                    return@launch
                }

                val options = LiteRtGenerationOptions(
                    temperature = temperature,
                    maxTokens = maxTokens,
                    topK = topK,
                    topP = topP,
                    repetitionPenalty = repetitionPenalty,
                )

                val streamed = session.streamText(prompt, options) { token ->
                    if (token.isNotEmpty()) {
                        sendEvent(token)
                    }
                }

                if (!streamed) {
                    val fullResponse = session.generateText(prompt, options)
                    fullResponse
                        .split(Regex("\\s+"))
                        .filter { it.isNotBlank() }
                        .forEach { token ->
                            if (!isActive) return@forEach
                            sendEvent("$token ")
                        }
                }

                sendEvent("[DONE]")

            } catch (e: CancellationException) {
                log("Generation cancelled")
                sendEvent("[DONE]")
            } catch (e: Exception) {
                log("Error in streaming generation: ${e.message}")
                sendEventError("GENERATION_ERROR", e.message ?: "Unknown error")
            } finally {
                isGenerating = false
            }
        }
    }

    private fun cancelGeneration() {
        if (isGenerating) {
            generationJob?.cancel()
            isGenerating = false
            log("Generation cancelled by user")
        }
    }

    // ========================================================================
    // Device information
    // ========================================================================

    private fun getDeviceCapabilities(): Map<String, Boolean> {
        return mapOf(
            "cpu" to true,
            "gpu" to hasGpuSupport(),
            "npu" to hasNpuSupport()
        )
    }

    private fun getReadinessReport(): Map<String, Any> {
        val capabilities = getDeviceCapabilities()
        val memoryInfo = getMemoryInfo()

        val sdkInt = Build.VERSION.SDK_INT
        val totalMemory = memoryInfo["totalMemory"] ?: 0L
        val availableMemory = memoryInfo["availableMemory"] ?: 0L

        val supported64BitAbis = Build.SUPPORTED_64_BIT_ABIS?.toList() ?: emptyList()
        val has64BitAbi = supported64BitAbis.any {
            it.equals("arm64-v8a", ignoreCase = true) ||
                it.equals("x86_64", ignoreCase = true)
        }

        val unsupportedReasons = mutableListOf<String>()
        val warnings = mutableListOf<String>()

        if (sdkInt < MIN_ANDROID_API) {
            unsupportedReasons.add(
                "Android ${Build.VERSION.RELEASE} (API $sdkInt) is below minimum API $MIN_ANDROID_API"
            )
        }

        if (!has64BitAbi) {
            unsupportedReasons.add("64-bit ABI required (arm64-v8a or x86_64)")
        }

        if (totalMemory in 1 until MIN_TOTAL_MEMORY_BYTES) {
            unsupportedReasons.add(
                "Insufficient total RAM (${formatBytes(totalMemory)}). Minimum ${formatBytes(MIN_TOTAL_MEMORY_BYTES)} required"
            )
        }

        if (totalMemory >= MIN_TOTAL_MEMORY_BYTES && totalMemory < RECOMMENDED_TOTAL_MEMORY_BYTES) {
            warnings.add(
                "RAM is limited (${formatBytes(totalMemory)}). Performance may be reduced; ${formatBytes(RECOMMENDED_TOTAL_MEMORY_BYTES)}+ recommended"
            )
        }

        if (availableMemory in 1 until MIN_AVAILABLE_MEMORY_BYTES) {
            warnings.add(
                "Low free RAM (${formatBytes(availableMemory)}). Close background apps before running on-device inference"
            )
        }

        if (capabilities["gpu"] != true && capabilities["npu"] != true) {
            warnings.add("No GPU/NPU acceleration detected. CPU inference may be slow")
        }

        if (!runtimeBridge.isRuntimeAvailable()) {
            unsupportedReasons.add(runtimeBridge.getRuntimeUnavailableReason())
        }

        val isSupported = unsupportedReasons.isEmpty()

        return mapOf(
            "isSupported" to isSupported,
            "androidApi" to sdkInt,
            "androidVersion" to Build.VERSION.RELEASE,
            "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "cpu" to (capabilities["cpu"] ?: true),
            "gpu" to (capabilities["gpu"] ?: false),
            "npu" to (capabilities["npu"] ?: false),
            "has64BitAbi" to has64BitAbi,
            "supported64BitAbis" to supported64BitAbis,
            "totalMemory" to totalMemory,
            "availableMemory" to availableMemory,
            "unsupportedReasons" to unsupportedReasons,
            "warnings" to warnings,
        )
    }

    private fun formatBytes(bytes: Long): String {
        if (bytes <= 0) return "0 B"
        val gb = bytes.toDouble() / (1024 * 1024 * 1024)
        return String.format("%.1f GB", gb)
    }

    private fun hasGpuSupport(): Boolean {
        // Check for GPU support
        // Most modern Android devices support GPU acceleration
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
    }

    private fun hasNpuSupport(): Boolean {
        // NPU support is device-specific
        // Check for known NPU-capable chipsets
        val manufacturer = Build.MANUFACTURER.lowercase()
        val model = Build.MODEL.lowercase()
        val hardware = Build.HARDWARE.lowercase()

        // Qualcomm NPU (Hexagon DSP)
        if (hardware.contains("qcom") || hardware.contains("snapdragon")) {
            return true
        }

        // MediaTek APU
        if (hardware.contains("mt") || manufacturer.contains("mediatek")) {
            return true
        }

        // Samsung Exynos NPU
        if (hardware.contains("exynos") || (manufacturer == "samsung" && model.contains("sm-"))) {
            return true
        }

        // Google Tensor
        if (hardware.contains("tensor") || model.contains("pixel")) {
            return Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
        }

        return false
    }

    private fun getMemoryInfo(): Map<String, Long> {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)

        return mapOf(
            "totalMemory" to memInfo.totalMem,
            "availableMemory" to memInfo.availMem,
            "threshold" to memInfo.threshold,
            "lowMemory" to if (memInfo.lowMemory) 1L else 0L,
            "modelMemory" to getEstimatedModelMemory()
        )
    }

    private fun getEstimatedModelMemory(): Long {
        // Estimate memory used by the loaded model
        // This is approximate - actual usage depends on the model
        if (!isEngineLoaded || currentModelPath == null) return 0

        val modelFile = File(currentModelPath!!)
        if (!modelFile.exists()) return 0

        // Models typically use 1.5-2x their file size in memory
        return (modelFile.length() * 1.5).toLong()
    }

    private fun getBenchmarkResults(): Map<String, Double> {
        return mapOf(
            "loadTimeMs" to lastLoadTimeMs.toDouble(),
            "prefillTokensPerSec" to lastPrefillTokensPerSec,
            "decodeTokensPerSec" to lastDecodeTokensPerSec
        )
    }

    // ========================================================================
    // Event helpers
    // ========================================================================

    private fun sendEvent(data: String) {
        mainHandler.post {
            eventSink?.success(data)
        }
    }

    private fun sendEventError(code: String, message: String) {
        mainHandler.post {
            eventSink?.success(mapOf("error" to "$code: $message"))
        }
    }

    private fun log(message: String) {
        android.util.Log.d(TAG, message)
    }
}

private data class LiteRtGenerationOptions(
    val temperature: Double,
    val maxTokens: Int?,
    val topK: Int,
    val topP: Double,
    val repetitionPenalty: Double,
)

private interface LiteRtRuntimeSession {
    fun generateText(prompt: String, options: LiteRtGenerationOptions): String
    fun streamText(
        prompt: String,
        options: LiteRtGenerationOptions,
        onToken: (String) -> Unit,
    ): Boolean

    fun close()
}

private interface LiteRtRuntimeBridge {
    fun isRuntimeAvailable(): Boolean
    fun getRuntimeUnavailableReason(): String
    fun openSession(modelPath: String, backend: String): LiteRtRuntimeSession
}

private class ReflectionLiteRtRuntimeBridge : LiteRtRuntimeBridge {
    private val modelAssetsClassNames = listOf(
        "com.google.ai.edge.litert.lm.ModelAssets",
        "com.google.ai.edge.litert.ModelAssets",
    )
    private val engineSettingsClassNames = listOf(
        "com.google.ai.edge.litert.lm.EngineSettings",
        "com.google.ai.edge.litert.EngineSettings",
    )
    private val engineClassNames = listOf(
        "com.google.ai.edge.litert.lm.Engine",
        "com.google.ai.edge.litert.Engine",
    )
    private val backendClassNames = listOf(
        "com.google.ai.edge.litert.lm.Backend",
        "com.google.ai.edge.litert.Backend",
    )

    override fun isRuntimeAvailable(): Boolean {
        return resolveClass(modelAssetsClassNames) != null &&
            resolveClass(engineSettingsClassNames) != null &&
            resolveClass(engineClassNames) != null
    }

    override fun getRuntimeUnavailableReason(): String {
        return "LiteRT-LM runtime dependency is missing. Add LiteRT-LM Android artifacts and native binaries before using on-device mode."
    }

    override fun openSession(modelPath: String, backend: String): LiteRtRuntimeSession {
        val modelAssetsClass = resolveClass(modelAssetsClassNames)
            ?: throw IllegalStateException(getRuntimeUnavailableReason())
        val engineSettingsClass = resolveClass(engineSettingsClassNames)
            ?: throw IllegalStateException(getRuntimeUnavailableReason())
        val engineClass = resolveClass(engineClassNames)
            ?: throw IllegalStateException(getRuntimeUnavailableReason())

        val modelAssets = invokeStaticByNames(
            clazz = modelAssetsClass,
            methodNames = listOf("create", "fromPath"),
            args = arrayOf(modelPath),
        ) ?: throw IllegalStateException("Unable to create LiteRT model assets")

        val backendValue = resolveBackend(backend)

        val engineSettings = if (backendValue != null) {
            invokeStaticByNames(
                clazz = engineSettingsClass,
                methodNames = listOf("createDefault", "create", "fromModelAssets"),
                args = arrayOf(modelAssets, backendValue),
            ) ?: invokeStaticByNames(
                clazz = engineSettingsClass,
                methodNames = listOf("createDefault", "create", "fromModelAssets"),
                args = arrayOf(modelAssets),
            )
        } else {
            invokeStaticByNames(
                clazz = engineSettingsClass,
                methodNames = listOf("createDefault", "create", "fromModelAssets"),
                args = arrayOf(modelAssets),
            )
        } ?: throw IllegalStateException("Unable to create LiteRT engine settings")

        val engine = invokeStaticByNames(
            clazz = engineClass,
            methodNames = listOf("createEngine", "create"),
            args = arrayOf(engineSettings),
        ) ?: throw IllegalStateException("Unable to create LiteRT engine instance")

        val conversation = invokeInstanceByNames(
            target = engine,
            methodNames = listOf("createConversation", "newConversation"),
            args = emptyArray(),
        ) ?: engine

        return ReflectionLiteRtRuntimeSession(engine = engine, conversation = conversation)
    }

    private fun resolveBackend(backend: String): Any? {
        val backendClass = resolveClass(backendClassNames) ?: return null
        val constants = backendClass.enumConstants ?: return null
        return constants.firstOrNull {
            (it as? Enum<*>)?.name?.equals(backend, ignoreCase = true) == true
        } ?: constants.firstOrNull {
            (it as? Enum<*>)?.name?.equals("CPU", ignoreCase = true) == true
        }
    }

    private fun resolveClass(candidates: List<String>): Class<*>? {
        for (candidate in candidates) {
            try {
                return Class.forName(candidate)
            } catch (_: ClassNotFoundException) {
                // Continue searching candidate names
            }
        }
        return null
    }

    private fun invokeStaticByNames(clazz: Class<*>, methodNames: List<String>, args: Array<Any?>): Any? {
        val method = clazz.methods.firstOrNull { m ->
            Modifier.isStatic(m.modifiers) &&
                methodNames.any { it.equals(m.name, ignoreCase = true) } &&
                m.parameterTypes.size == args.size
        } ?: return null

        return method.invoke(null, *args)
    }

    private fun invokeInstanceByNames(target: Any, methodNames: List<String>, args: Array<Any?>): Any? {
        val method = target.javaClass.methods.firstOrNull { m ->
            methodNames.any { it.equals(m.name, ignoreCase = true) } &&
                m.parameterTypes.size == args.size
        } ?: return null

        return method.invoke(target, *args)
    }
}

private class ReflectionLiteRtRuntimeSession(
    private val engine: Any,
    private val conversation: Any,
) : LiteRtRuntimeSession {
    override fun generateText(prompt: String, options: LiteRtGenerationOptions): String {
        val direct = invokeGeneration(prompt)
            ?: throw IllegalStateException("No compatible LiteRT generation method found")

        return extractText(direct)
    }

    override fun streamText(
        prompt: String,
        options: LiteRtGenerationOptions,
        onToken: (String) -> Unit,
    ): Boolean {
        // Reflection-based async callback signatures are SDK-version specific.
        // For now, rely on sync generation + token chunk fallback in caller.
        return false
    }

    override fun close() {
        invokeClose(conversation)
        if (conversation !== engine) {
            invokeClose(engine)
        }
    }

    private fun invokeGeneration(prompt: String): Any? {
        val methodNames = listOf("sendMessage", "generate", "run")
        val method = conversation.javaClass.methods.firstOrNull { m ->
            methodNames.any { it.equals(m.name, ignoreCase = true) } &&
                m.parameterTypes.size == 1 &&
                m.parameterTypes[0].isAssignableFrom(String::class.java)
        } ?: conversation.javaClass.methods.firstOrNull { m ->
            methodNames.any { it.equals(m.name, ignoreCase = true) } &&
                m.parameterTypes.size == 1 &&
                m.parameterTypes[0] == CharSequence::class.java
        }

        return method?.invoke(conversation, prompt)
    }

    private fun invokeClose(target: Any) {
        val closeMethod = target.javaClass.methods.firstOrNull {
            it.name.equals("close", ignoreCase = true) && it.parameterCount == 0
        } ?: return
        closeMethod.invoke(target)
    }

    private fun extractText(response: Any?): String {
        if (response == null) return ""
        if (response is String) return response

        val method = response.javaClass.methods.firstOrNull {
            (it.name.equals("getContent", ignoreCase = true) ||
                it.name.equals("content", ignoreCase = true) ||
                it.name.equals("getText", ignoreCase = true) ||
                it.name.equals("text", ignoreCase = true)) &&
                it.parameterCount == 0
        }

        val extracted = method?.invoke(response)
        if (extracted is String) return extracted

        return response.toString()
    }
}
