import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/state/view_state.dart';
import '../models/alert.dart';
import '../providers/alert_provider.dart';
import '../widgets/alert_tile.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AlertProvider>().load(),
    );
  }

  List<Alert> _filter(List<Alert> alerts) {
    if (_query.isEmpty) return alerts;
    final q = _query.toLowerCase();
    return alerts
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.location.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add),
        label: const Text('Novo alerta'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por título ou local...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(AlertProvider provider) {
    switch (provider.state) {
      case ViewState.loading:
      case ViewState.idle:
        return const LoadingView(message: 'Carregando alertas...');
      case ViewState.error:
        return ErrorView(
          message: provider.errorMessage ?? 'Erro ao carregar alertas.',
          onRetry: () => context.read<AlertProvider>().load(),
        );
      case ViewState.success:
        final alerts = _filter(provider.alerts);
        if (alerts.isEmpty) {
          return const EmptyView(message: 'Nenhum alerta encontrado.');
        }
        return RefreshIndicator(
          onRefresh: () => context.read<AlertProvider>().load(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            itemCount: alerts.length,
            itemBuilder: (_, i) => AlertTile(alert: alerts[i]),
          ),
        );
    }
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateAlertSheet(),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerta criado com sucesso.')),
      );
    }
  }
}

/// Bottom sheet with a validated form to create a new alert.
class _CreateAlertSheet extends StatefulWidget {
  const _CreateAlertSheet();

  @override
  State<_CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<_CreateAlertSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  AlertSeverity _severity = AlertSeverity.medium;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final alert = Alert(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      severity: _severity,
      location: _locationController.text.trim(),
      createdAt: DateTime.now(),
    );

    final ok = await context.read<AlertProvider>().createAlert(alert);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Novo alerta',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Local'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o local' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AlertSeverity>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Severidade'),
              items: AlertSeverity.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _severity = v ?? _severity),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
