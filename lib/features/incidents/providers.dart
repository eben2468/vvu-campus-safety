import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../models/app_settings.dart';
import '../../models/chat_message.dart';
import '../../models/incident.dart';
import '../../models/incident_event.dart';
import '../../services/api_client.dart';
import '../../services/firestore_service.dart';
import '../auth/providers.dart';
import '../sos/providers.dart';
import 'data/chat_repository.dart';
import 'data/incident_repository.dart';
import 'data/photo_repository.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(
    ref.watch(firestoreProvider),
    ref.watch(apiClientProvider),
  );
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(ref.watch(apiClientProvider));
});

/// One incident, live.
final incidentProvider = StreamProvider.family<Incident?, String>((ref, id) {
  return ref.watch(incidentRepositoryProvider).watchIncident(id);
});

/// An incident's timeline, oldest first.
final incidentEventsProvider =
    StreamProvider.family<List<IncidentEvent>, String>((ref, id) {
      return ref.watch(incidentRepositoryProvider).watchEvents(id);
    });

/// The signed-in user's own incidents, newest first.
final myIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final uid = ref.watch(sessionProvider.select((s) => s.profile?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(incidentRepositoryProvider).watchMyIncidents(uid);
});

final reportControllerProvider = Provider<ReportController>(
  ReportController.new,
);

/// Submits an incident report: uploads the photos, then writes the
/// incident (`onIncidentCreated` notifies officers).
class ReportController {
  ReportController(this._ref);

  final Ref _ref;

  Future<String> submit({
    required String category,
    required String description,
    required List<Uint8List> photos,
    GeoPoint? location,
  }) async {
    final reporter = _ref.read(sessionProvider).profile;
    if (reporter == null) {
      throw const AppException('Your profile is still loading. Try again.');
    }
    final incidents = _ref.read(incidentRepositoryProvider);
    final incidentId = incidents.newIncidentId();
    final mediaUrls = photos.isEmpty
        ? const <String>[]
        : await _ref
              .read(photoRepositoryProvider)
              .upload(incidentId: incidentId, photos: photos);
    final settings =
        _ref.read(appSettingsProvider).value ?? const AppSettings();

    await incidents.createReport(
      incidentId: incidentId,
      reporter: reporter,
      category: category,
      description: description.trim(),
      mediaUrls: mediaUrls,
      location: location,
      locationLabel: location == null ? null : settings.zoneNameFor(location),
    );
    return incidentId;
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.watch(firestoreProvider),
    ref.watch(apiClientProvider),
  );
});

/// An incident's chat, oldest first.
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  incidentId,
) {
  return ref.watch(chatRepositoryProvider).watchMessages(incidentId);
});
