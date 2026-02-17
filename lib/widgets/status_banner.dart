import 'dart:async';
import 'package:flutter/material.dart';
import 'package:private_chat_hub/services/status_service.dart';

class StatusBanner extends StatefulWidget {
  const StatusBanner({super.key});

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner> {
  String? _message;
  late final StreamSubscription<String?> _sub;

  @override
  void initState() {
    super.initState();
    _sub = StatusService().persistentStream.listen((msg) {
      setState(() {
        _message = msg;
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_message == null || _message!.isEmpty) return const SizedBox.shrink();
    return MaterialBanner(
      content: Text(_message!),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      actions: [
        TextButton(
          onPressed: () => StatusService().setPersistent(null),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
