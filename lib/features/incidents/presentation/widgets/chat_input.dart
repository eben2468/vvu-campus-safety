import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/chat_repository.dart';
import '../../data/photo_repository.dart';

/// Text box with photo and send buttons. Calls [onSend] with the text and
/// an optional compressed photo; clears itself when sending succeeds.
class ChatInput extends StatefulWidget {
  const ChatInput({super.key, required this.onSend});

  final Future<void> Function(String text, Uint8List? photo) onSend;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _text = TextEditingController();
  Uint8List? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      // The dashboard (web) picks a file; phones open the camera.
      final file = await ImagePicker().pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      );
      if (file == null) return;
      final bytes = await PhotoRepository.compress(await file.readAsBytes());
      setState(() => _photo = bytes);
    } on AppException catch (e) {
      _show(e.message);
    } catch (_) {
      _show('Could not open the camera. Check the app permissions.');
    }
  }

  Future<void> _send() async {
    if (_text.text.trim().isEmpty && _photo == null) return;
    setState(() => _busy = true);
    try {
      await widget.onSend(_text.text, _photo);
      _text.clear();
      setState(() => _photo = null);
    } on AppException catch (e) {
      _show(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_photo != null)
              ListTile(
                leading: Image.memory(
                  _photo!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
                title: const Text('Photo attached'),
                trailing: IconButton(
                  tooltip: 'Remove photo',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _photo = null),
                ),
              ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Take a photo',
                  icon: const Icon(Icons.photo_camera),
                  onPressed: _busy ? null : _pickPhoto,
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: ChatRepository.maxMessageLength,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      counterText: '',
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Send',
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _busy ? null : _send,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
