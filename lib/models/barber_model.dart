import 'service_model.dart';
import 'review_model.dart';

class Barber {
  final String id;
  final String name;
  final String coverImage;
  final String avatarImage;
  final double rating;
  final int reviewCount;
  final String address;
  final String city;
  final String about;
  final Map<String, String> workingHours;
  final double latitude;
  final double longitude;
  final List<ServiceModel> services;
  final List<String> portfolioImages;
  final List<ReviewModel> reviews;
  final String? phone;
  final String venueType;
  final String? todayOpen;
  final String? todayClose;
  final bool todayClosed;
  final double? minPrice;

  const Barber({
    required this.id,
    required this.name,
    required this.coverImage,
    required this.avatarImage,
    required this.rating,
    required this.reviewCount,
    required this.address,
    required this.city,
    required this.about,
    required this.workingHours,
    required this.latitude,
    required this.longitude,
    required this.services,
    required this.portfolioImages,
    required this.reviews,
    this.phone,
    this.venueType = 'barber',
    this.todayOpen,
    this.todayClose,
    this.todayClosed = true,
    this.minPrice,
  });

  factory Barber.fromSummaryJson(Map<String, dynamic> j) {
    return Barber(
      id: j['id'] as String,
      name: j['name'] as String,
      coverImage: (j['coverImage'] as String?) ?? '',
      avatarImage: (j['avatarImage'] as String?) ?? '',
      rating: (j['rating'] as num).toDouble(),
      reviewCount: j['reviewCount'] as int,
      address: j['address'] as String,
      city: (j['city'] as Map<String, dynamic>)['name'] as String,
      about: '',
      workingHours: const {},
      latitude: 0,
      longitude: 0,
      services: const [],
      portfolioImages: const [],
      reviews: const [],
      phone: null,
      venueType: (j['venueType'] as String?) ?? 'barber',
      todayOpen: j['todayOpen'] as String?,
      todayClose: j['todayClose'] as String?,
      todayClosed: (j['todayClosed'] as bool?) ?? true,
      minPrice: j['minPrice'] != null ? (j['minPrice'] as num).toDouble() : null,
    );
  }

  factory Barber.fromDetailJson(Map<String, dynamic> j) {
    final hoursMap = <String, String>{};
    for (final h in (j['workingHours'] as List)) {
      final day = _capitalize(h['day'] as String);
      final closed = h['isClosed'] as bool;
      hoursMap[day] = closed
          ? 'Closed'
          : '${h['openTime']} – ${h['closeTime']}';
    }

    return Barber(
      id: j['id'] as String,
      name: j['name'] as String,
      coverImage: (j['coverImage'] as String?) ?? '',
      avatarImage: (j['avatarImage'] as String?) ?? '',
      rating: (j['rating'] as num).toDouble(),
      reviewCount: j['reviewCount'] as int,
      address: j['address'] as String,
      city: (j['city'] as Map<String, dynamic>)['name'] as String,
      about: (j['about'] as String?) ?? '',
      workingHours: hoursMap,
      latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
      services: (j['services'] as List)
          .map<ServiceModel>((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      portfolioImages: (j['portfolio'] as List)
          .map<String>((p) => (p as Map<String, dynamic>)['imageUrl'] as String)
          .toList(),
      reviews: const [],
      phone: j['phone'] as String?,
      venueType: (j['venueType'] as String?) ?? 'barber',
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'name':        name,
    'coverImage':  coverImage,
    'avatarImage': avatarImage,
    'rating':      rating,
    'reviewCount': reviewCount,
    'address':     address,
    'city':        city,
  };

  factory Barber.fromSavedJson(Map<String, dynamic> j) => Barber(
    id:            j['id'] as String,
    name:          j['name'] as String,
    coverImage:    (j['coverImage'] as String?) ?? '',
    avatarImage:   (j['avatarImage'] as String?) ?? '',
    rating:        (j['rating'] as num).toDouble(),
    reviewCount:   (j['reviewCount'] as num).toInt(),
    address:       j['address'] as String,
    city:          j['city'] as String,
    about:         '',
    workingHours:  const {},
    latitude:      0,
    longitude:     0,
    services:      const [],
    portfolioImages: const [],
    reviews:       const [],
  );

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
