import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/app_settings.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../../sos/providers.dart';
import '../../data/settings_text.dart';
import '../../providers.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import 'widgets/category_editor.dart';

/// App settings (PRD §4.12): report categories, Security Office number,
/// SOS countdown, campus boundary and zones. Saved through
/// `adminUpdateSettings`, which records the change in the audit log.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _boundary = TextEditingController();
  final _zones = TextEditingController();
  List<String> _categories = const [];
  int _countdown = 3;
  bool _loaded = false;
  bool _busy = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _phone.dispose();
    _boundary.dispose();
    _zones.dispose();
    super.dispose();
  }

  /// Fills the form once, from the first settings that arrive.
  void _load(AppSettings settings) {
    _loaded = true;
    _categories = settings.categories;
    _countdown = settings.sosCountdownSec;
    _phone.text = settings.securityPhone;
    _boundary.text = boundaryToText(settings.campusBoundary);
    _zones.text = zonesToText(settings.zones);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final boundary = parseBoundary(_boundary.text);
    final zones = parseZones(_zones.text);
    final error = boundary.error ?? zones.error;
    if (error != null) return _show(error, isError: true);

    setState(() => _busy = true);
    try {
      final changed = await ref
          .read(adminRepositoryProvider)
          .updateSettings(
            AppSettings(
              categories: _categories,
              securityPhone: normalizeGhanaPhone(_phone.text)!,
              sosCountdownSec: _countdown,
              campusBoundary: boundary.value!,
              zones: zones.value!,
            ),
          );
      _show(changed.isEmpty ? 'Nothing changed.' : 'Settings saved.');
    } on AppException catch (e) {
      _show(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message, {bool isError = false}) => setState(() {
    _message = message;
    _isError = isError;
  });

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    if (!_loaded) {
      if (!settings.hasValue) {
        return const Center(child: CircularProgressIndicator());
      }
      _load(settings.value!);
    }
    final categories = SectionCard(
      title: 'Report categories',
      subtitle: 'The choices on the report form',
      icon: Icons.category_outlined,
      child: CategoryEditor(
        categories: _categories,
        onChanged: (list) => setState(() => _categories = list),
      ),
    );
    final response = SectionCard(
      title: 'Emergency response',
      subtitle: 'Used by every phone',
      icon: Icons.sos,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Security Office emergency number',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Shown on the "Call security" buttons. +233 format.',
            ),
            validator: Validators.ghanaPhone,
          ),
          const SizedBox(height: 20),
          DropdownMenu<int>(
            expandedInsets: EdgeInsets.zero,
            label: const Text('SOS countdown'),
            leadingIcon: const Icon(Icons.timer_outlined),
            initialSelection: _countdown,
            onSelected: (value) => setState(() => _countdown = value!),
            helperText: 'Time to cancel after pressing SOS. 0 sends at once.',
            dropdownMenuEntries: [
              for (var s = 0; s <= 10; s++)
                DropdownMenuEntry(value: s, label: '$s seconds'),
            ],
          ),
        ],
      ),
    );
    final campus = SectionCard(
      title: 'Campus map',
      subtitle:
          'Right-click a spot in Google Maps or OpenStreetMap to copy '
          'its coordinates',
      icon: Icons.map_outlined,
      child: Wrap(
        spacing: kGap,
        runSpacing: kGap,
        children: [
          _CoordinatesField(
            label: 'Campus boundary',
            help:
                'One point per line as "latitude, longitude", going round '
                'the campus. Leave empty for no boundary.',
            hint: '5.797, -0.126',
            controller: _boundary,
          ),
          _CoordinatesField(
            label: 'Campus zones',
            help:
                'One zone per line as "name, latitude, longitude, radius in '
                'metres". Incidents inside a zone are labelled with its name.',
            hint: 'Hostels, 5.795, -0.124, 150',
            controller: _zones,
          ),
        ],
      ),
    );

    // A Column, not a ListView: a ListView drops fields scrolled out of
    // view, and Form.validate() then silently skips them.
    return Form(
      key: _form,
      child: SingleChildScrollView(
        padding: kPagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Settings',
              subtitle:
                  'Changes reach every phone within seconds and are '
                  'recorded in the audit log.',
              actions: [
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_busy ? 'Saving…' : 'Save settings'),
                ),
              ],
            ),
            if (_message != null) FormMessage(_message!, isError: _isError),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1000) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      categories,
                      const SizedBox(height: kGap),
                      response,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: categories),
                    const SizedBox(width: kGap),
                    Expanded(child: response),
                  ],
                );
              },
            ),
            const SizedBox(height: kGap),
            campus,
          ],
        ),
      ),
    );
  }
}

/// A labelled monospace text area for coordinates, half the card wide on
/// a desktop.
class _CoordinatesField extends StatelessWidget {
  const _CoordinatesField({
    required this.label,
    required this.help,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String help;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth >= 900
            ? (constraints.maxWidth - kGap) / 2
            : constraints.maxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              help,
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 6,
              maxLines: 14,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(hintText: hint),
            ),
          ],
        ),
      ),
    );
  }
}
