enum CraneStatus { working, idle, off, overload, error }

class CraneModel {
  final String id;
  final String name;
  final CraneStatus status;
  final int currentLoad; // kg
  final int capacity; // kg
  final List<String> deviceIds;
  final int health; // percent
  final DateTime updatedAt;

  CraneModel({
    required this.id,
    required this.name,
    required this.status,
    required this.currentLoad,
    required this.capacity,
    required this.deviceIds,
    required this.health,
    required this.updatedAt,
  });
}

// Mock data used by dashboard
final List<CraneModel> mockCranes = [
  CraneModel(
    id: 'CRN-001',
    name: 'Gantry Crane #1',
    status: CraneStatus.working,
    currentLoad: 4250,
    capacity: 5000,
    deviceIds: ['DEV-001', 'DEV-002'],
    health: 94,
    updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
  ),
  CraneModel(
    id: 'CRN-002',
    name: 'Overhead Crane #2',
    status: CraneStatus.idle,
    currentLoad: 0,
    capacity: 10000,
    deviceIds: ['DEV-003'],
    health: 88,
    updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
  CraneModel(
    id: 'CRN-003',
    name: 'Jib Crane #3',
    status: CraneStatus.overload,
    currentLoad: 6200,
    capacity: 5000,
    deviceIds: ['DEV-004'],
    health: 76,
    updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
  ),
  CraneModel(
    id: 'CRN-004',
    name: 'Bridge Crane #4',
    status: CraneStatus.error,
    currentLoad: 3800,
    capacity: 8000,
    deviceIds: ['DEV-005'],
    health: 65,
    updatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
  ),
  CraneModel(
    id: 'CRN-005',
    name: 'Gantry Crane #5',
    status: CraneStatus.off,
    currentLoad: 0,
    capacity: 8000,
    deviceIds: ['DEV-006'],
    health: 90,
    updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
];
