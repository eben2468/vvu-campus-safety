import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../routing/routes.dart';
import '../../../services/location_service.dart';
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../../sos/providers.dart';
import '../providers.dart';
import 'widgets/location_picker.dart';
import 'widgets/photo_picker_field.dart';

/// Report a non-urgent incident with photos and a location (PRD §4.3).
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String? _category;
  List<Uint8List> _photos = const [];
  GeoPoint? _location;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _useCurrentLocation();
  }

  Future<void> _useCurrentLocation() async {
    final position = await ref.read(locationServiceProvider).currentPosition();
    if (position != null && mounted && _location == null) {
      setState(
        () => _location = GeoPoint(position.latitude, position.longitude),
      );
    }
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final category = _category;
    if (!_formKey.currentState!.validate() || category == null) {
      // The highlighted field may be scrolled out of view.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose what happened and describe it, then send.'),
        ),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(reportControllerProvider)
          .submit(
            category: category,
            description: _description.text,
            photos: _photos,
            location: _location,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report sent. Security has been notified.'),
        ),
      );
      context.go(Routes.reportDetail(id));
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(appSettingsProvider).value?.categories ?? defaultCategories;
    return Scaffold(
      appBar: AppBar(title: const Text('Report an incident')),
      body: SafeArea(
        // A Column, not a ListView: a ListView drops fields scrolled out of
        // view, and Form.validate() then silently skips them.
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) FormMessage(_error!),
                DropdownButtonFormField<String>(
                  isExpanded: true, // fit narrow phones and large text
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                  ),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                  validator: (value) =>
                      value == null ? 'Choose a category.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What happened, when, and anyone involved',
                    alignLabelWithHint: true,
                  ),
                  minLines: 4,
                  maxLines: 8,
                  maxLength: maxDescriptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.reportDescription,
                ),
                const SizedBox(height: 8),
                PhotoPickerField(
                  photos: _photos,
                  onChanged: (photos) => setState(() => _photos = photos),
                ),
                const SizedBox(height: 16),
                LocationPicker(
                  value: _location,
                  onChanged: (point) => setState(() => _location = point),
                ),
                const SizedBox(height: 8),
                Text(
                  'Security will see your name and phone number with this report.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SubmitButton(
                  label: 'Send report',
                  busy: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
