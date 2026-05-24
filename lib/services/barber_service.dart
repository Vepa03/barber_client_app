import '../models/barber_model.dart';
import '../models/review_model.dart';
import 'api_client.dart';

class BarberService {
  static Future<List<Map<String, String>>> getCities() async {
    final data = await ApiClient.get('/cities') as List;
    return data
        .map<Map<String, String>>((c) => {
              'id': c['id'] as String,
              'name': c['name'] as String,
              'slug': c['slug'] as String,
            })
        .toList();
  }

  static Future<List<Barber>> getBarbers({
    String? citySlug,
    String? search,
    String? venueType,
  }) async {
    var path = '/barbers';
    final params = <String>[];
    if (citySlug != null) params.add('city=$citySlug');
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }
    if (venueType != null) params.add('venueType=$venueType');
    if (params.isNotEmpty) path += '?${params.join('&')}';

    final data = await ApiClient.get(path) as List;
    return data.map<Barber>((j) => Barber.fromSummaryJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Barber> getBarberDetail(String id) async {
    final data = await ApiClient.get('/barbers/$id') as Map<String, dynamic>;
    return Barber.fromDetailJson(data);
  }

  static Future<List<ReviewModel>> getBarberReviews(String id) async {
    final data = await ApiClient.get('/barbers/$id/reviews') as List;
    return data
        .map<ReviewModel>((j) => ReviewModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Returns the appointmentId if the user can review, null otherwise.
  static Future<String?> getReviewableAppointmentId(String barberId) async {
    final data = await ApiClient.get('/barbers/$barberId/can-review')
        as Map<String, dynamic>;
    if (data['canReview'] == true) return data['appointmentId'] as String?;
    return null;
  }

  static Future<void> submitReview(
    String appointmentId, {
    required int rating,
    String? comment,
  }) async {
    await ApiClient.post('/appointments/$appointmentId/review', {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  static Future<List<({int startMin, int endMin})>> getBusySlots(
      String barberId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final data = await ApiClient.get(
        '/barbers/$barberId/busy-slots?date=$dateStr') as List;
    return data.map<({int startMin, int endMin})>((j) {
      final dt       = DateTime.parse(j['scheduledAt'] as String).toLocal();
      final startMin = dt.hour * 60 + dt.minute;
      final endMin   = startMin + (j['durationMin'] as int);
      return (startMin: startMin, endMin: endMin);
    }).toList();
  }
}
