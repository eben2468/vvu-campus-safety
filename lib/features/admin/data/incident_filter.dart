import 'package:flutter/foundation.dart';

import '../../../core/constants.dart';
import '../../../models/incident.dart';

/// Which incidents the dashboard's incidents table shows.
enum StatusFilter {
  open('Open'),
  closed('Closed'),
  all('All');

  const StatusFilter(this.label);

  final String label;
}

/// The filters above the incidents table. Applied in the app to the most
/// recent incidents (see `DashboardRepository.watchRecentIncidents`).
@immutable
class IncidentFilter {
  const IncidentFilter({
    this.status = StatusFilter.all,
    this.kind,
    this.category,
    this.search = '',
  });

  final StatusFilter status;

  /// Null for SOS and reports.
  final IncidentKind? kind;

  /// Null for every category.
  final String? category;

  /// Matches the reporter's name, the place or the incident id.
  final String search;

  bool matches(Incident incident) {
    switch (status) {
      case StatusFilter.open when !incident.active:
      case StatusFilter.closed when incident.active:
        return false;
      default:
    }
    if (kind != null && incident.kind != kind) return false;
    if (category != null && incident.category != category) return false;

    final query = search.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      incident.reporterName,
      incident.locationLabel ?? '',
      incident.id,
      incident.status.label,
    ].any((text) => text.toLowerCase().contains(query));
  }

  List<Incident> apply(List<Incident> incidents) =>
      incidents.where(matches).toList();

  // Nullable fields take a function so they can be reset to null.
  IncidentFilter copyWith({
    StatusFilter? status,
    IncidentKind? Function()? kind,
    String? Function()? category,
    String? search,
  }) => IncidentFilter(
    status: status ?? this.status,
    kind: kind == null ? this.kind : kind(),
    category: category == null ? this.category : category(),
    search: search ?? this.search,
  );
}
