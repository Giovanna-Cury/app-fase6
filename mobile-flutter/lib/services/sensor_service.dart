import '../core/network/api_client.dart';
import '../models/sensor.dart';
import '../models/telemetry.dart';

/// Talks to the sensor endpoints of the Spring Boot API.
///
/// Endpoints:
///  * `GET /api/sensors`      -> list all sensors
///  * `GET /api/sensors/{id}` -> single sensor
///  * `GET /api/sensors/{id}/readings`   -> telemetry history (Fase 6)
///  * `GET /api/sensors/{id}/indicators` -> PL/SQL indicators (Fase 6)
///  * `POST /api/sensors/{id}/readings`  -> triggers PRC_REGISTRAR_LEITURA
class SensorService {
  SensorService(this._api);

  final ApiClient _api;

  Future<List<Sensor>> fetchAll() async {
    final data = await _api.get('/sensors');
    return (data as List)
        .map((e) => Sensor.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Sensor> fetchById(String id) async {
    final data = await _api.get('/sensors/$id');
    return Sensor.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<List<SensorReading>> fetchReadings(String id, {int limit = 30}) async {
    final data = await _api.get('/sensors/$id/readings?limit=$limit');
    return (data as List)
        .map((e) => SensorReading.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<SensorIndicators> fetchIndicators(String id) async {
    final data = await _api.get('/sensors/$id/indicators');
    return SensorIndicators.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<ReadingRegistration> registerReading(String id, double value) async {
    final data =
        await _api.post('/sensors/$id/readings', body: {'value': value});
    return ReadingRegistration.fromJson((data as Map).cast<String, dynamic>());
  }
}
