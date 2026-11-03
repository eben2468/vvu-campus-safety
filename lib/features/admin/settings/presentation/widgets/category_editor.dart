import 'package:flutter/material.dart';

import '../../../../../core/theme.dart';

/// Report categories as removable chips plus a box to add one.
class CategoryEditor extends StatefulWidget {
  const CategoryEditor({
    super.key,
    required this.categories,
    required this.onChanged,
  });

  final List<String> categories;
  final ValueChanged<List<String>> onChanged;

  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  final _input = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final name = _input.text.trim();
    final taken = widget.categories.any(
      (c) => c.toLowerCase() == name.toLowerCase(),
    );
    setState(() {
      _error = name.isEmpty
          ? 'Type a category first.'
          : taken
          ? 'That category already exists.'
          : name.toLowerCase() == 'emergency'
          ? '"emergency" is used for SOS alerts.'
          : null;
    });
    if (_error != null) return;
    widget.onChanged([...widget.categories, name]);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in widget.categories)
              InputChip(
                label: Text(c),
                // Keep at least one category.
                onDeleted: widget.categories.length == 1
                    ? null
                    : () => widget.onChanged(
                        widget.categories.where((x) => x != c).toList(),
                      ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _input,
                maxLength: 40,
                decoration: InputDecoration(
                  hintText: 'New category',
                  errorText: _error,
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        Text(
          'Existing reports keep their category if you remove it here.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
