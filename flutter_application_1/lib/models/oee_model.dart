class OeeModel {
  final double oee; // 0..1
  final double availability; // 0..1
  final double performance; // 0..1
  final double quality; // 0..1

  OeeModel({
    required this.oee,
    required this.availability,
    required this.performance,
    required this.quality,
  });
}

final OeeModel mockOee = OeeModel(
  oee: 0.16,
  availability: 0.25,
  performance: 0.68,
  quality: 0.94,
);
