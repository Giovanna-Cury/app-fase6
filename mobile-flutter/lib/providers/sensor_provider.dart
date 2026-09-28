import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/state/view_state.dart';
import '../models/sensor.dart';
import '../repositories/sensor_repository.dart';

/// Exposes the list of sensors and derived dashboard statistics.
class SensorProvider extends ChangeNotifier {
  SensorProvider(this._repository);

  final SensorRepository _repository;

  ViewState _state = ViewState.idle;
  List<Sensor> _sensors = [];
  String? _errorMessage;

  ViewState get state => _state;
  List<Sensor> get sensors => List.unmodifiable(_sensors);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;

  int get onlineCount =>
      _sensors.where((s) => s.status == SensorStatus.online).length;
  int get warningCount =>
      _sensors.where((s) => s.status == SensorStatus.warning).length;
  int get offlineCount =>
      _sensors.where((s) => s.status == SensorStatus.offline).length;
  int get total => _sensors.length;

  Future<void> load() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _sensors = await _repository.getSensors();
      _state = ViewState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ViewState.error;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar os sensores.';
      _state = ViewState.error;
    }
    notifyListeners();
  }
}
