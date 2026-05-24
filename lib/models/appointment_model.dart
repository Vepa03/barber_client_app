class AppointmentBarberInfo {
  final String id;
  final String name;
  final String? coverImage;
  final String address;
  final String city;
  final String venueType;

  const AppointmentBarberInfo({
    required this.id,
    required this.name,
    this.coverImage,
    required this.address,
    required this.city,
    this.venueType = 'barber',
  });

  factory AppointmentBarberInfo.fromJson(Map<String, dynamic> j) =>
      AppointmentBarberInfo(
        id:         j['id'] as String,
        name:       j['name'] as String,
        coverImage: j['coverImage'] as String?,
        address:    j['address'] as String,
        city:       j['city'] as String,
        venueType:  (j['venueType'] as String?) ?? 'barber',
      );
}

class AppointmentServiceInfo {
  final String id;
  final String name;
  final double price;
  final int durationMin;
  final String? icon;

  const AppointmentServiceInfo({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMin,
    this.icon,
  });

  factory AppointmentServiceInfo.fromJson(Map<String, dynamic> j) =>
      AppointmentServiceInfo(
        id:          j['id'] as String,
        name:        j['name'] as String,
        price:       (j['price'] as num).toDouble(),
        durationMin: j['durationMin'] as int,
        icon:        j['icon'] as String?,
      );
}

class AppointmentModel {
  final String id;
  final DateTime scheduledAt;
  final double totalPrice;
  final int totalDurationMin;
  final String status;
  final String? notes;
  final bool reviewed;
  final AppointmentBarberInfo barber;
  final List<AppointmentServiceInfo> services;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.scheduledAt,
    required this.totalPrice,
    required this.totalDurationMin,
    required this.status,
    this.notes,
    this.reviewed = false,
    required this.barber,
    required this.services,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) =>
      AppointmentModel(
        id:               j['id'] as String,
        scheduledAt:      DateTime.parse(j['scheduledAt'] as String).toLocal(),
        totalPrice:       (j['totalPrice'] as num).toDouble(),
        totalDurationMin: j['totalDurationMin'] as int,
        status:           j['status'] as String,
        notes:            j['notes'] as String?,
        reviewed:         (j['reviewed'] as bool?) ?? false,
        barber:           AppointmentBarberInfo.fromJson(j['barber'] as Map<String, dynamic>),
        services:         (j['services'] as List)
            .map((s) => AppointmentServiceInfo.fromJson(s as Map<String, dynamic>))
            .toList(),
        createdAt:        DateTime.parse(j['createdAt'] as String).toLocal(),
      );

  bool get isPending     => status == 'pending';
  bool get isConfirmed   => status == 'confirmed';
  bool get isCompleted   => status == 'completed';
  bool get isCancelled   => status == 'cancelled';
  bool get canCancel     => isPending || isConfirmed;
  bool get canReschedule => isPending || isConfirmed;
}
