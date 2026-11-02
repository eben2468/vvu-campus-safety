import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/photo_repository.dart';

/// Up to [maxIncidentPhotos] photos from the camera or gallery, compressed
/// as they are picked so the upload is quick on mobile data.
class PhotoPickerField extends StatefulWidget {
  const PhotoPickerField({
    super.key,
    required this.photos,
    required this.onChanged,
  });

  final List<Uint8List> photos;
  final ValueChanged<List<Uint8List>> onChanged;

  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(source: source);
      if (file == null) return;
      final bytes = await PhotoRepository.compress(await file.readAsBytes());
      widget.onChanged([...widget.photos, bytes]);
    } on AppException catch (e) {
      _show(e.message);
    } catch (_) {
      // Most often camera or photo permission was refused.
      _show(
        'Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}. '
        'Check the app permissions in your phone settings.',
      );
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
    final photos = widget.photos;
    final canAdd = photos.length < maxIncidentPhotos && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (optional, up to $maxIncidentPhotos)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (photos.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _Thumbnail(
                bytes: photos[i],
                onRemove: () => widget.onChanged([...photos]..removeAt(i)),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canAdd ? () => _pick(ImageSource.camera) : null,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canAdd ? () => _pick(ImageSource.gallery) : null,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(bytes, width: 96, height: 96, fit: BoxFit.cover),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton.filledTonal(
            tooltip: 'Remove photo',
            iconSize: 18,
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
