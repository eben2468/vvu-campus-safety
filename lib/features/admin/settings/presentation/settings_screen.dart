import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/app_settings.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../../sos/providers.dart';
import '../../data/settings_text.dart';
import '../../providers.dart';
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
    final textTheme = Theme.of(context).textTheme;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: textTheme.titleMedium),
    );

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Settings', style: textTheme.headlineSmall),
          if (_message != null) ...[
            const SizedBox(height: 12),
            FormMessage(_message!, isError: _isError),
          ],
          heading('Report categories'),
          CategoryEditor(
            categories: _categories,
            onChanged: (list) => setState(() => _categories = list),
          ),
          heading('Security Office emergency number'),
          SizedBox(
            width: 320,
            child: TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                helperText: 'Shown on the "Call security" buttons.',
              ),
              validator: Validators.ghanaPhone,
            ),
          ),
          heading('SOS countdown'),
          DropdownMenu<int>(
            initialSelection: _countdown,
            onSelected: (value) => setState(() => _countdown = value!),
            helperText: 'Time to cancel after pressing SOS. 0 sends at once.',
            dropdownMenuEntries: [
              for (var s = 0; s <= 10; s++)
                DropdownMenuEntry(value: s, label: '$s seconds'),
            ],
          ),
          heading('Campus boundary'),
          const Text(
            'One point per line as "latitude, longitude", going round the '
            'campus. Right-click a spot in Google Maps to copy its '
            'coordinates. Leave empty for no boundary.',
          ),
          _textArea(_boundary, '5.797, -0.126'),
          heading('Campus zones'),
          const Text(
            'One zone per line as "name, latitude, longitude, radius in '
            'metres". Incidents inside a zone are labelled with its name.',
          ),
          _textArea(_zones, 'Hostels, 5.795, -0.124, 150'),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_busy ? 'Saving…' : 'Save settings'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _textArea(TextEditingController controller, String hint) =>
      TextField(
        controller: controller,
        minLines: 4,
        maxLines: 12,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: InputDecoration(hintText: hint),
      );
}
