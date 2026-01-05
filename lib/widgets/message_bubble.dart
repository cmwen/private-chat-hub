import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/widgets/tool_widgets.dart';
import 'package:intl/intl.dart';

/// A chat message bubble widget.
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMe = message.isMe;

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.secondary,
                child: const Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe ? colorScheme.primary : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display status message if present
                    if (message.statusMessage != null)
                      _buildStatusMessage(context),
                    // Display tool badges for assistant messages
                    if (!message.isMe && message.hasToolCalls)
                      _buildToolBadges(context),
                    // Display image attachments if present
                    if (message.hasImages) _buildImageAttachments(context),
                    // Display text file attachments if present
                    if (message.hasTextFiles) _buildFileAttachments(context),
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    // Display web search references if present
                    if (!message.isMe && message.webSearchReferences.isNotEmpty)
                      _buildWebReferences(context),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              const Icon(Icons.done_all, size: 16, color: Colors.blue),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildToolBadges(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: message.toolCalls.map((toolCall) {
          return ToolBadge(
            toolCall: toolCall,
            onTap: () => _showToolCallDetails(context, toolCall),
          );
        }).toList(),
      ),
    );
  }

  void _showToolCallDetails(BuildContext context, toolCall) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ToolBadge(toolCall: toolCall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ToolCallDetails(toolCall: toolCall),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAttachments(BuildContext context) {
    final images = message.images;
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: images.map((attachment) {
          return GestureDetector(
            onTap: () => _showImageFullscreen(context, attachment),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                attachment.data,
                width: images.length == 1 ? 200 : 100,
                height: images.length == 1 ? 200 : 100,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileAttachments(BuildContext context) {
    final files = message.textFiles;
    if (files.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: files.map((attachment) {
          return GestureDetector(
            onTap: () => _showFileContent(context, attachment),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFileIcon(attachment.name),
                    size: 16,
                    color: message.isMe ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: message.isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          attachment.formattedSize,
                          style: TextStyle(
                            fontSize: 10,
                            color: message.isMe
                                ? Colors.white70
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'py':
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

  void _showFileContent(BuildContext context, Attachment attachment) {
    final content = attachment.textContent ?? 'Unable to read file content';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getFileIcon(attachment.name)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attachment.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              Text(
                attachment.formattedSize,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageFullscreen(BuildContext context, Attachment attachment) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(dialogContext),
              child: InteractiveViewer(child: Image.memory(attachment.data)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  Widget _buildStatusMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                message.isMe ? Colors.white70 : Colors.grey[600]!,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.statusMessage!,
              style: TextStyle(
                color: message.isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebReferences(BuildContext context) {
    final references = message.webSearchReferences;
    
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link,
                size: 14,
                color: message.isMe ? Colors.white70 : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Sources (${references.length})',
                style: TextStyle(
                  color: message.isMe ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: references.take(5).map((url) {
              // Extract domain from URL
              final uri = Uri.tryParse(url);
              final domain = uri?.host.replaceFirst('www.', '') ?? url;
              
              return InkWell(
                onTap: () => _launchUrl(context, url),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: message.isMe
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new,
                        size: 10,
                        color: message.isMe ? Colors.white : Colors.black87,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          domain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: message.isMe ? Colors.white : Colors.black87,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (references.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${references.length - 5} more',
                style: TextStyle(
                  color: message.isMe ? Colors.white60 : Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _launchUrl(BuildContext context, String url) {
    // Show URL in a bottom sheet with copy option
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Source URL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
