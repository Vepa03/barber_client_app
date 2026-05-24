import '../models/appointment_model.dart';
import 'api_client.dart';

class AppointmentService {
  static Future<List<AppointmentModel>> getMyAppointments() async {
    final data = await ApiClient.get('/appointments') as List;
    return data
        .map((j) => AppointmentModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<AppointmentModel> book({
    required String barberId,
    required List<String> serviceIds,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    final data = await ApiClient.post('/appointments', {
      'barberId':    barberId,
      'serviceIds':  serviceIds,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      if (notes != null) 'notes': notes,
    }) as Map<String, dynamic>;
    return AppointmentModel.fromJson(data);
  }

  static Future<void> cancel(String id) async {
    await ApiClient.patch('/appointments/$id/cancel', {});
  }

  static Future<void> review(
    String id, {
    required int rating,
    String? comment,
  }) async {
    await ApiClient.post('/appointments/$id/review', {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  static Future<AppointmentModel> reschedule(
      String id, DateTime newDateTime) async {
    final data = await ApiClient.patch('/appointments/$id/reschedule', {
      'scheduledAt': newDateTime.toUtc().toIso8601String(),
    }) as Map<String, dynamic>;
    return AppointmentModel.fromJson(data);
  }
}
