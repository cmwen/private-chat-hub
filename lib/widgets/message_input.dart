import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:uuid/uuid.dart';

/// Callback for sending a message with optional attachments.
typedef OnSendMessageWithAttachments =
    void Function(String text, List<Attachment> attachments);

/// Message input field with send button and attachment support.
class MessageInput extends StatefulWidget {
  final Function(String)? onSendMessage;
  final OnSendMessageWithAttachments? onSendMessageWithAttachments;
  final bool enableAttachments;
  final bool supportsVision;
  final bool supportsTools;
  final bool toolCallingEnabled;
  final bool isLoading;
  final VoidCallback? onStopGeneration;
  final ValueChanged<bool>? onToggleToolCalling;

  const MessageInput({
    super.key,
    this.onSendMessage,
    this.onSendMessageWithAttachments,
    this.enableAttachments = true,
    this.supportsVision = true,
    this.supportsTools = false,
    this.toolCallingEnabled = true,
    this.isLoading = false,
    this.onStopGeneration,
    this.onToggleToolCalling,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<Attachment> _attachments = [];
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  bool get _canSend => _hasText || _attachments.isNotEmpty;

  void _handleSend() {
    final text = _controller.text.trim();
    if (!_canSend) return;

    if (widget.onSendMessageWithAttachments != null) {
      widget.onSendMessageWithAttachments!(text, List.from(_attachments));
    } else if (widget.onSendMessage != null && text.isNotEmpty) {
      widget.onSendMessage!(text);
    }

    _controller.clear();
    setState(() {
      _attachments.clear();
    });
  }

  /// Supported text file extensions for context attachments.
  static const List<String> _supportedTextExtensions = [
    'txt',
    'md',
    'py',
    'js',
    'ts',
    'java',
    'kt',
    'dart',
    'json',
    'yaml',
    'yml',
    'xml',
    'html',
    'css',
    'c',
    'cpp',
    'h',
    'hpp',
    'cs',
    'go',
    'rb',
    'php',
    'swift',
    'rs',
    'sh',
  ];

  /// Maximum file size for text attachments (5 MB).
  static const int _maxTextFileSize = 5 * 1024 * 1024;

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo from Gallery'),
              subtitle: const Text('For vision models'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              subtitle: const Text('For vision models'),
              onTap: () {
                Navigator.pop(sheetContext);
                _takePhoto();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('File'),
              subtitle: const Text('Code, text, markdown files'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedTextExtensions,
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        for (final file in result.files) {
          await _addFileAttachment(file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
      }
    }
  }

  Future<void> _addFileAttachment(PlatformFile file) async {
    // Validate file size
    if (file.size > _maxTextFileSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} is too large (max 5 MB)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Get file bytes
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to read ${file.name}')));
      }
      return;
    }

    // Determine MIME type from extension
    final extension = file.extension?.toLowerCase() ?? 'txt';
    final mimeType = _getMimeType(extension);

    setState(() {
      _attachments.add(
        Attachment(
          id: const Uuid().v4(),
          name: file.name,
          mimeType: mimeType,
          data: bytes!,
          size: bytes.length,
        ),
      );
    });
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      case 'json':
        return 'application/json';
      case 'yaml':
      case 'yml':
        return 'text/yaml';
      case 'xml':
        return 'text/xml';
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'py':
        return 'text/x-python';
      case 'js':
      case 'ts':
        return 'text/javascript';
      case 'java':
        return 'text/x-java';
      case 'kt':
        return 'text/x-kotlin';
      case 'dart':
        return 'text/x-dart';
      case 'c':
      case 'h':
        return 'text/x-c';
      case 'cpp':
      case 'hpp':
        return 'text/x-c++';
      case 'cs':
        return 'text/x-csharp';
      case 'go':
        return 'text/x-go';
      case 'rb':
        return 'text/x-ruby';
      case 'php':
        return 'text/x-php';
      case 'swift':
        return 'text/x-swift';
      case 'rs':
        return 'text/x-rust';
      case 'sh':
        return 'text/x-shellscript';
      default:
        return 'text/plain';
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      for (final image in images) {
        await _addImageAttachment(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _addImageAttachment(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
      }
    }
  }

  Future<void> _addImageAttachment(XFile image) async {
    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? 'image/jpeg';

    setState(() {
      _attachments.add(
        Attachment(
          id: const Uuid().v4(),
          name: image.name,
          mimeType: mimeType,
          data: bytes,
          size: bytes.length,
        ),
      );
    });
  }

  void _removeAttachment(String id) {
    setState(() {
      _attachments.removeWhere((a) => a.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Interactive capability chips
            if (widget.supportsTools || widget.supportsVision)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (widget.supportsTools)
                      FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.build_circle,
                              size: 14,
                              color: widget.toolCallingEnabled
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            const Text('Tools'),
                          ],
                        ),
                        selected: widget.toolCallingEnabled,
                        onSelected: widget.onToggleToolCalling != null
                            ? (selected) =>
                                  widget.onToggleToolCalling!(selected)
                            : null,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        selectedColor: colorScheme.primaryContainer,
                        checkmarkColor: colorScheme.onPrimaryContainer,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: widget.toolCallingEnabled
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (widget.supportsTools && widget.supportsVision)
                      const SizedBox(width: 8),
                    if (widget.supportsVision)
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            const Text('Vision'),
                          ],
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            // Attachment previews
            if (_attachments.isNotEmpty) _buildAttachmentPreviews(),
            // Input row
            Row(
              children: [
                if (widget.enableAttachments && widget.supportsVision)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: colorScheme.primary,
                    onPressed: _showAttachmentOptions,
                    tooltip: 'Attach image (vision required)',
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.isLoading)
                  ElevatedButton(
                    onPressed: widget.onStopGeneration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop, size: 18),
                        SizedBox(width: 6),
                        Text('Stop'),
                      ],
                    ),
                  )
                else
                  CircleAvatar(
                    backgroundColor: _canSend
                        ? colorScheme.primary
                        : Colors.grey[300],
                    child: IconButton(
                      icon: Icon(
                        _canSend ? Icons.send : Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _canSend ? _handleSend : () {},
                      tooltip: _canSend ? 'Send message' : 'Voice message',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreviews() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          final attachment = _attachments[index];
          return _AttachmentPreview(
            attachment: attachment,
            onRemove: () => _removeAttachment(attachment.id),
          );
        },
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;

  const _AttachmentPreview({required this.attachment, required this.onRemove});

  IconData _getFileIcon() {
    final ext = attachment.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'py':
        return Icons.code;
      case 'js':
      case 'ts':
      case 'dart':
      case 'java':
      case 'kt':
      case 'c':
      case 'cpp':
      case 'h':
      case 'cs':
      case 'go':
      case 'rb':
      case 'php':
      case 'swift':
      case 'rs':
        return Icons.code;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
        return Icons.data_object;
      case 'md':
        return Icons.article;
      case 'txt':
        return Icons.description;
      case 'html':
      case 'css':
        return Icons.web;
      case 'sh':
        return Icons.terminal;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    final ext = attachment.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'py':
        return Colors.blue;
      case 'js':
      case 'ts':
        return Colors.yellow.shade700;
      case 'dart':
        return Colors.teal;
      case 'java':
      case 'kt':
        return Colors.orange;
      case 'json':
        return Colors.green;
      case 'md':
        return Colors.purple;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: attachment.isImage
                ? Image.memory(
                    attachment.data,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getFileIcon(), color: _getFileColor(), size: 24),
                        const SizedBox(height: 4),
                        Text(
                          attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          attachment.formattedSize,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
