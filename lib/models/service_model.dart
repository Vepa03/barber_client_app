class ServiceModel {
  final String id;
  final String name;
  final String duration;
  final double price;
  final String icon;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    required this.icon,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> j) {
    return ServiceModel(
      id: j['id'] as String,
      name: j['name'] as String,
      duration: '${j['durationMin']} min',
      price: (j['price'] as num).toDouble(),
      icon: (j['icon'] as String?) ?? '✂️',
    );
  }
}
