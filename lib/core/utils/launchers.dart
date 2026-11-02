import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer with [phone] filled in.
Future<bool> callNumber(String phone) =>
    launchUrl(Uri(scheme: 'tel', path: phone));

/// Opens the SMS app with [phone] and [body] filled in.
Future<bool> textNumber(String phone, String body) =>
    launchUrl(Uri.parse('sms:$phone?body=${Uri.encodeComponent(body)}'));

/// Walking directions in Google Maps (app if installed, else browser).
Future<bool> openDirections(double latitude, double longitude) => launchUrl(
  Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$latitude,$longitude&travelmode=walking',
  ),
  mode: LaunchMode.externalApplication,
);

/// A Google Maps link to a point, e.g. for an SMS to security.
String mapsLink(double latitude, double longitude) =>
    'https://maps.google.com/?q=$latitude,$longitude';
