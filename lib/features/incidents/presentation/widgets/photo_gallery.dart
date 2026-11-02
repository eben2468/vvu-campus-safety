import 'package:flutter/material.dart';

/// A row of incident photos; tap one to view it full screen.
class PhotoGallery extends StatelessWidget {
  const PhotoGallery({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _FullScreenPhoto(url: urls[i]),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              urls[i],
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              semanticLabel: 'Photo ${i + 1} of ${urls.length}',
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const SizedBox.square(
                      dimension: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (_, _, _) => const SizedBox.square(
                dimension: 120,
                child: Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  const _FullScreenPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: InteractiveViewer(child: Center(child: Image.network(url))),
    );
  }
}
