/// An error with a message that is safe to show to the user as-is.
///
/// Repositories catch Firebase exceptions and rethrow them as
/// [AppException] so screens never deal with Firebase error codes.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
