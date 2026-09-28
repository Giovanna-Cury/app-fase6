import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/network/api_exception.dart';
import '../models/sensor.dart';
import '../models/telemetry.dart';
import '../repositories/sensor_repository.dart';

/// Sensor detail: PL/SQL indicators, telemetry history and a form that sends
/// a new reading (REST → Java → JDBC → PRC_REGISTRAR_LEITURA).
class SensorDetailScreen extends StatefulWidget {
  const SensorDetailScreen({super.key, required this.sensor});

  final Sensor sensor;

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  late final SensorRepository _repository;

  SensorIndicators? _indicators;
  List<SensorReading> _readings = const [];
  bool _loading = true;
  String? _error;

  Sensor get sensor => widget.sensor;

  @override
  void initState() {
    super.initState();
    _repository = context.read<SensorRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final indicators = await _repository.getIndicators(sensor);
      final readings = await _repository.getReadings(sensor);
      if (!mounted) return;
      setState(() {
        _indicators = indicators;
        _readings = readings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Não foi possível carregar o sensor.';
        _loading = false;
      });
    }
  }

  Future<void> _registerReading() async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _ReadingDialog(sensor: sensor),
    );
    if (value == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _repository.registerReading(sensor, value);
      final alert =
          result.alertId != null ? ' · alerta automático #${result.alertId}' : '';
      messenger.showSnackBar(SnackBar(
        backgroundColor: result.classification.color,
        content: Text('Leitura ${result.classification.label.toUpperCase()}$alert'),
      ));
      await _load();
    } on ApiException catch (e) {
      // Business errors come from PL/SQL (RAISE_APPLICATION_ERROR -> 404/422).
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = _readings.isNotEmpty ? _readings.first : null;
    final headline = latest != null
        ? '${latest.value.toStringAsFixed(2)} ${sensor.unit ?? ''}'
        : sensor.formattedValue;

    return Scaffold(
      appBar: AppBar(title: Text(sensor.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registerReading,
        icon: const Icon(Icons.add_chart),
        label: const Text('Registrar leitura'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: sensor.status.color.withValues(alpha: 0.15),
                    child: Icon(sensor.status.icon,
                        size: 44, color: sensor.status.color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    headline,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (latest != null)
                    Text(
                      latest.classification.label,
                      style: TextStyle(color: latest.classification.color),
                    )
                  else
                    Text(
                      sensor.status.label,
                      style: TextStyle(color: sensor.status.color),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loading && _indicators == null)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text(_error!),
                  trailing: TextButton(
                      onPressed: _load, child: const Text('Tentar novamente')),
                ),
              )
            else if (_indicators != null)
              _IndicatorsSection(indicators: _indicators!),
            const SizedBox(height: 12),
            _InfoRow(label: 'Tipo', value: sensor.type),
            _InfoRow(label: 'Local', value: sensor.location),
            _InfoRow(
              label: 'Limites (alerta / crítico)',
              value: '${_fmt(sensor.alertThreshold)} / '
                  '${_fmt(sensor.criticalThreshold)} ${sensor.unit ?? ''}',
            ),
            _InfoRow(
                label: 'Responsável', value: sensor.responsibleName ?? '—'),
            _InfoRow(
              label: 'Coordenadas',
              value: sensor.latitude != null && sensor.longitude != null
                  ? '${sensor.latitude!.toStringAsFixed(4)}, '
                      '${sensor.longitude!.toStringAsFixed(4)}'
                  : 'Não informado',
            ),
            const SizedBox(height: 20),
            Text('Histórico de leituras', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_readings.isEmpty && !_loading)
              const Card(
                child: ListTile(title: Text('Nenhuma leitura registrada.')),
              ),
            ..._readings.map(
              (r) => Card(
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.circle, size: 14, color: r.classification.color),
                  title: Text('${r.value.toStringAsFixed(2)} ${sensor.unit ?? ''}'),
                  subtitle: Text(_dateTime.format(r.readAt)),
                  trailing: Text(
                    r.classification.label,
                    style: TextStyle(
                      color: r.classification.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double? value) => value == null ? '—' : value.toStringAsFixed(0);
}

/// Three KPI tiles + the formatted last reading returned by the database.
class _IndicatorsSection extends StatelessWidget {
  const _IndicatorsSection({required this.indicators});

  final SensorIndicators indicators;

  static String _pct(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final riskColor = indicators.riskIndex >= 50
        ? Colors.red
        : indicators.riskIndex >= 20
            ? Colors.orange
            : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _IndicatorTile(label: 'Conformidade 24h', value: _pct(indicators.conformity24h)),
            _IndicatorTile(label: 'Conformidade 7d', value: _pct(indicators.conformity7d)),
            _IndicatorTile(
              label: 'Risco (${indicators.riskLevel})',
              value: '${indicators.riskIndex}',
              color: riskColor,
            ),
          ],
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storage_rounded),
            title: Text(indicators.formattedLastReading),
            subtitle: Text(indicators.engineLabel),
          ),
        ),
      ],
    );
  }
}

class _IndicatorTile extends StatelessWidget {
  const _IndicatorTile({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog that validates and returns the measured value.
class _ReadingDialog extends StatefulWidget {
  const _ReadingDialog({required this.sensor});

  final Sensor sensor;

  @override
  State<_ReadingDialog> createState() => _ReadingDialogState();
}

class _ReadingDialogState extends State<_ReadingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? _parse(String? text) =>
      double.tryParse((text ?? '').trim().replaceAll(',', '.'));

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _parse(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar leitura'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            labelText: 'Valor medido',
            suffixText: widget.sensor.unit,
            helperText: 'Limites: ${widget.sensor.alertThreshold ?? '—'} / '
                '${widget.sensor.criticalThreshold ?? '—'}',
          ),
          validator: (text) => _parse(text) == null ? 'Informe um número válido' : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Enviar')),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
