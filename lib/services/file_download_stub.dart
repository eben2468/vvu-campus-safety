/// Downloads are only offered on the web dashboard.
void downloadTextFile(
  String fileName,
  String text, {
  String mimeType = 'text/csv',
}) {
  throw UnsupportedError('Downloads are only available on the web dashboard.');
}
