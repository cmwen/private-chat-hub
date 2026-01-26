import 'package:private_chat_hub/core/utils/result.dart';
import 'package:private_chat_hub/domain/entities/ollama_model.dart';

abstract class IModelRepository {
  Future<Result<List<OllamaModel>>> getModels();

  Future<Result<OllamaModel>> getModel(String name);

  Future<Result<void>> deleteModel(String name);

  Stream<PullProgress> pullModel(String name);

  Future<Result<ModelDetails>> getModelDetails(String name);

  Future<Result<List<String>>> getCachedModelNames();

  Future<Result<void>> refreshModels();
}
