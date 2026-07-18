import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../data/ticket_model.dart';
import '../data/ticket_service.dart';

class MisTicketsPage extends StatefulWidget {
  const MisTicketsPage({super.key});

  @override
  State<MisTicketsPage> createState() => _MisTicketsPageState();
}

class _MisTicketsPageState extends State<MisTicketsPage> {
  final _ticketService = TicketService();
  final _tokenStorage = TokenStorage();

  List<TicketModel> _tickets = [];
  String? _selectedStatus;
  bool _loading = true;
  String? _error;
  bool _showCreateForm = false;

  List<TicketModel> get _filteredTickets {
    if (_selectedStatus == null) return _tickets;
    return _tickets
        .where((t) => t.status.toUpperCase() == _selectedStatus)
        .toList();
  }

  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _creating = false;
  String? _createError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final hasToken = await _tokenStorage.hasAccessToken();
    if (!hasToken) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.customerLogin);
      return;
    }

    try {
      final tickets = await _ticketService.getTickets();
      if (!mounted) return;
      setState(() => _tickets = tickets);
    } catch (error) {
      if (!mounted) return;
      if (error is DioException &&
          (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403)) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.customerLogin);
        return;
      }
      setState(() => _error = 'No se pudieron cargar los tickets.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTicket() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      setState(() => _createError = 'Completa el asunto y el mensaje.');
      return;
    }

    setState(() {
      _creating = true;
      _createError = null;
    });

    try {
      await _ticketService.createTicket(
        subject: subject,
        initialMessage: message,
      );
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      setState(() => _showCreateForm = false);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _createError = _readError(error);
      });
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  String _readError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msgs = data.values.expand((v) => v is List ? v : [v]).join(' ');
        if (msgs.isNotEmpty) return msgs;
      }
      if (data != null) return data.toString();
    }
    return 'No se pudo crear el ticket.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tickets de soporte'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() => _showCreateForm = !_showCreateForm);
        },
        icon: Icon(_showCreateForm ? Icons.close : Icons.add),
        label: Text(_showCreateForm ? 'Cancelar' : 'Nuevo ticket'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.wifi_off_outlined, size: 58, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      );
    }

    final filtered = _filteredTickets;

    return Column(
      children: [
        if (!_showCreateForm)
          _TicketStatusFilterChips(
            selected: _selectedStatus,
            onSelected: (s) => setState(() => _selectedStatus = s),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
            children: [
              if (_showCreateForm) ...[
                _CreateTicketForm(
                  subjectController: _subjectController,
                  messageController: _messageController,
                  creating: _creating,
                  error: _createError,
                  onSubmit: _createTicket,
                ),
                const SizedBox(height: 20),
              ],
              if (_tickets.isEmpty && !_showCreateForm)
                _EmptyTickets()
              else if (filtered.isEmpty && !_showCreateForm)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(
                    children: [
                      const Icon(Icons.filter_list_off,
                          size: 58, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No hay tickets con ese estado.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedStatus = null),
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  '${filtered.length} ticket${filtered.length == 1 ? '' : 's'}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ...filtered.map(
                  (ticket) => _TicketCard(
                    ticket: ticket,
                    onTap: () async {
                      await Navigator.of(context).pushNamed(
                        AppRoutes.ticketDetail,
                        arguments: ticket.id,
                      );
                      await _load();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateTicketForm extends StatelessWidget {
  const _CreateTicketForm({
    required this.subjectController,
    required this.messageController,
    required this.creating,
    required this.onSubmit,
    this.error,
  });

  final TextEditingController subjectController;
  final TextEditingController messageController;
  final bool creating;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nuevo ticket',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Asunto',
                hintText: 'Describe brevemente tu problema',
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 120,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Mensaje inicial',
                hintText: 'Explica en detalle tu consulta o problema...',
                prefixIcon: Icon(Icons.message_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 1000,
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(
                error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: creating ? null : onSubmit,
              icon: creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(creating ? 'Enviando...' : 'Enviar ticket'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final TicketModel ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusStyle(ticket.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket.updatedAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusStyle(String status) {
    return switch (status) {
      'OPEN' => ('Abierto', Colors.amber.shade700),
      'IN_PROGRESS' => ('En progreso', Colors.blue.shade600),
      'RESOLVED' => ('Resuelto', Colors.green.shade600),
      'CLOSED' => ('Cerrado', Colors.grey.shade600),
      _ => (status, Colors.grey),
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TicketStatusFilterChips extends StatelessWidget {
  const _TicketStatusFilterChips({
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _filters = [
    (null, 'Todos'),
    ('OPEN', 'Abierto'),
    ('IN_PROGRESS', 'En progreso'),
    ('RESOLVED', 'Resuelto'),
    ('CLOSED', 'Cerrado'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          for (final (value, label) in _filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTickets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const Icon(Icons.support_agent_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 14),
          Text(
            'Sin tickets de soporte',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Toca "Nuevo ticket" para enviar una consulta.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
