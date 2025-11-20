class AlertModel {
  final String id;
  final String message;
  final String severity; // e.g., Critical, Warning, Info
  final DateTime time;

  AlertModel({
    required this.id,
    required this.message,
    required this.severity,
    required this.time,
  });
}

final List<AlertModel> mockAlerts = [
  AlertModel(id: 'A1', message: 'Overload on Jib Crane #3', severity: 'Critical', time: DateTime.now().subtract(const Duration(minutes: 1))),
  AlertModel(id: 'A2', message: 'Device DEV-005 battery low', severity: 'Warning', time: DateTime.now().subtract(const Duration(minutes: 10)))
];
