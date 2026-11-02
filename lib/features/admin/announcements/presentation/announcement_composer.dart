import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../../auth/providers.dart';
import '../../../notifications/providers.dart';

/// Form to post an announcement; it is pushed to the chosen audience.
class AnnouncementComposer extends ConsumerStatefulWidget {
  const AnnouncementComposer({super.key});

  @override
  ConsumerState<AnnouncementComposer> createState() =>
      _AnnouncementComposerState();
}

class _AnnouncementComposerState extends ConsumerState<AnnouncementComposer> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  AnnouncementAudience _audience = AnnouncementAudience.all;
  bool _busy = false;
  String? _error;

  static const _audienceLabels = {
    AnnouncementAudience.all: 'Everyone',
    AnnouncementAudience.students: 'Students',
    AnnouncementAudience.staff: 'Staff',
    AnnouncementAudience.officers: 'Officers',
  };

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (!_form.currentState!.validate()) return;
    final uid = ref.read(sessionProvider).profile?.uid;
    if (uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(announcementRepositoryProvider)
          .post(
            title: _title.text,
            body: _body.text,
            audience: _audience,
            byUid: uid,
          );
      _title.clear();
      _body.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent to ${_audienceLabels[_audience]!.toLowerCase()}.',
            ),
          ),
        );
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? value, String what) =>
        (value ?? '').trim().isEmpty ? 'Write a $what.' : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New announcement',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_error != null) FormMessage(_error!),
              TextFormField(
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Title'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => required(v, 'title'),
              ),
              TextFormField(
                controller: _body,
                maxLength: 2000,
                minLines: 4,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Message'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => required(v, 'message'),
              ),
              const SizedBox(height: 8),
              Text('Send to', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              SegmentedButton<AnnouncementAudience>(
                segments: [
                  for (final a in AnnouncementAudience.values)
                    ButtonSegment(value: a, label: Text(_audienceLabels[a]!)),
                ],
                selected: {_audience},
                onSelectionChanged: (s) => setState(() => _audience = s.single),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _post,
                icon: const Icon(Icons.send),
                label: Text(_busy ? 'Sending…' : 'Send announcement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
