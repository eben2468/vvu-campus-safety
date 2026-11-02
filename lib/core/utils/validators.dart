import '../constants.dart';
import 'formatters.dart';

/// Form field validators. Each returns an error message, or null if valid.
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _idNumber = RegExp(r'^[A-Z0-9]{6,20}$');

  /// Minimum password length (docs/PRD.md §4.1).
  static const minPasswordLength = 8;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password.';
    if (value.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters.';
    }
    return null;
  }

  /// Validator for a "confirm password" field that must equal [original].
  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) return 'Re-enter your password.';
      if (value != original()) return 'Passwords do not match.';
      return null;
    };
  }

  static String? fullName(String? value) {
    final words = (value ?? '').trim().split(RegExp(r'\s+'));
    if (words.length < 2) return 'Enter your full name as on your VVU ID.';
    if (value!.length > 100) return 'Name is too long.';
    return null;
  }

  static String? idNumber(String? value) {
    final v = normalizeIdNumber(value ?? '');
    if (v.isEmpty) return 'Enter your VVU ID number.';
    if (!_idNumber.hasMatch(v)) {
      return 'Use letters and digits only, e.g. 223IT0100946.';
    }
    return null;
  }

  static String? ghanaPhone(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter your phone number.';
    if (normalizeGhanaPhone(value!) == null) {
      return 'Enter a Ghana number, e.g. 024 123 4567.';
    }
    return null;
  }

  static String? reportDescription(String? value) {
    final length = (value ?? '').trim().length;
    if (length < minDescriptionLength) {
      return 'Describe what happened (at least $minDescriptionLength characters).';
    }
    if (length > maxDescriptionLength) {
      return 'Keep it under $maxDescriptionLength characters.';
    }
    return null;
  }
}
