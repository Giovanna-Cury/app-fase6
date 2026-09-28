import '../core/network/api_client.dart';
import '../models/alert.dart';

/// Talks to the alert endpoints of the Spring Boot API.
///
/// Endpoints:
///  * `GET  /api/alerts`             -> list all alerts
///  * `POST /api/alerts`             -> create an alert
///  * `PUT  /api/alerts/{id}/resolve`-> mark an alert as resolved
class AlertService {
  AlertService(this._api);

  final ApiClient _api;

  Future<List<Alert>> fetchAll() async {
    final data = await _api.get('/alerts');
    return (data as List)
        .map((e) => Alert.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Alert> create(Alert alert) async {
    final data = await _api.post('/alerts', body: alert.toJson());
    return Alert.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Alert> resolve(String id) async {
    final data = await _api.put('/alerts/$id/resolve');
    return Alert.fromJson((data as Map).cast<String, dynamic>());
  }
}
