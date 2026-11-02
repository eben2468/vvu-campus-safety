import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local settings. Overridden in `main.dart` with the loaded
/// instance so reads are synchronous.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('Override sharedPreferencesProvider in main()'),
);

/// Whether this device has been through the permissions screen.
final onboardingDoneProvider = NotifierProvider<OnboardingDone, bool>(
  OnboardingDone.new,
);

class OnboardingDone extends Notifier<bool> {
  static const _key = 'onboardingDone';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> markDone() async {
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
    state = true;
  }
}
