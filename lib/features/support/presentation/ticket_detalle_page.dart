import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/ticket_model.dart';
import '../data/ticket_service.dart';

class TicketDetallePage extends StatefulWidget {
  const TicketDetallePage({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<TicketDetallePage> createState() => _TicketDetallePageState();
}

class _TicketDetallePageState extends State<TicketDetallePage> {
  final _ticketService = TicketService();
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  TicketModel? _ticket;
  List<TicketMessageModel> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await _ticketService.getMessages(widget.ticketId);
      if (!mounted) return;
      setState(() => _messages = messages);

      // Re-fetch ticket list to update status badge — we derive ticket info
      // from the messages endpoint; a lightweight detail fetch isn't needed.
      final tickets = await _ticketService.getTickets();
      if (!mounted) return;
      final ticket = tickets.where((t) => t.id == widget.ticketId).firstOrNull;
      setState(() => _ticket = ticket);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar el ticket.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await _ticketService.sendMessage(widget.ticketId, content);
      if (!mounted) return;
      _replyController.clear();
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readError(error))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resolve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como resuelto'),
        content: const Text(
          '¿Confirmas que tu problema fue resuelto? El ticket se cerrara.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _resolving = true);

    try {
      await _ticketService.resolveTicket(widget.ticketId);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readError(error))),
      );
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  String _readError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msgs =
            data.values.expand((v) => v is List ? v : [v]).join(' ');
        if (msgs.isNotEmpty) return msgs;
      }
      if (data != null) return data.toString();
    }
    return 'Ocurrio un error. Intenta nuevamente.';
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    final isClosed = ticket?.status == 'RESOLVED' || ticket?.status == 'CLOSED';
    final (statusLabel, statusColor) = _statusStyle(ticket?.status ?? 'OPEN');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ticket?.subject ?? 'Ticket #${widget.ticketId}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (ticket != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                backgroundColor: statusColor.withValues(alpha: 0.12),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : Column(
                    children: [
                      Expanded(
                        child: _messages.isEmpty
                            ? const _EmptyThread()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 16, 8),
                                itemCount: _messages.length,
                                itemBuilder: (_, i) =>
                                    _MessageBubble(message: _messages[i]),
                              ),
                      ),
                      if (!isClosed) ...[
                        const Divider(height: 1),
                        _ReplyBar(
                          controller: _replyController,
                          sending: _sending,
                          onSend: _sendReply,
                          onResolve: _resolving ? null : _resolve,
                        ),
                      ] else
                        _ClosedBanner(status: ticket?.status ?? 'CLOSED'),
                    ],
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
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TicketMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isFromCustomer;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.support_agent,
                  size: 16, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine && message.authorName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      message.authorName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMine ? scheme.onPrimary : scheme.onSurface,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')} '
        '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}';
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    this.onResolve,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu respuesta...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                tooltip: 'Enviar',
              ),
            ],
          ),
          if (onResolve != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onResolve,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Marcar como resuelto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade400),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  const _ClosedBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isResolved = status == 'RESOLVED';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: isResolved
          ? Colors.green.shade50
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isResolved ? Icons.check_circle : Icons.lock_outline,
            size: 18,
            color: isResolved ? Colors.green.shade700 : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isResolved
                ? 'Ticket resuelto. Gracias por contactarnos.'
                : 'Este ticket esta cerrado.',
            style: TextStyle(
              color: isResolved ? Colors.green.shade800 : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Sin mensajes todavia.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Colors.grey),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
