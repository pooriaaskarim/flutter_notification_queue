import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

/// A live event log that subscribes to [FlutterNotificationQueue.events] and
/// displays the last `_maxEvents` lifecycle events in real time.
class EventLogPanel extends StatefulWidget {
  const EventLogPanel({super.key});

  @override
  State<EventLogPanel> createState() => _EventLogPanelState();
}

class _EventLogPanelState extends State<EventLogPanel> {
  static const _maxEvents = 50;

  final _events = <_LogEntry>[];
  StreamSubscription<FnqEvent>? _sub;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sub = FlutterNotificationQueue.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onEvent(final FnqEvent event) {
    setState(() {
      _events.insert(0, _LogEntry(event: event, time: DateTime.now()));
      if (_events.length > _maxEvents) {
        _events.removeLast();
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.stream_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'EVENT LOG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (_events.isNotEmpty)
                _Badge(
                  label: '${_events.length}',
                  color: colorScheme.primary,
                ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Clear log',
                child: InkWell(
                  onTap: () => setState(_events.clear),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_sweep_outlined,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Event list ──
        Expanded(
          child: _events.isEmpty
              ? _EmptyState(colorScheme: colorScheme)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _events.length,
                  itemBuilder: (final context, final i) =>
                      _EventTile(entry: _events[i]),
                ),
        ),
      ],
    );
  }
}

// ── Tile ────────────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  const _EventTile({required this.entry});

  final _LogEntry entry;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final meta = _EventMeta.of(entry.event);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 52,
            child: Text(
              _formatTime(entry.time),
              style: TextStyle(
                fontSize: 9,
                fontFamily: 'monospace',
                color: colorScheme.onSurface.withValues(alpha: 0.35),
                height: 2.0,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Color dot
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: meta.color,
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      meta.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (meta.badge != null)
                      _Badge(label: meta.badge!, color: meta.color),
                  ],
                ),
                if (meta.subtitle != null)
                  Text(
                    meta.subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(final DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';
}

// ── Event meta mapping ──────────────────────────────────────────────────────

class _EventMeta {
  const _EventMeta({
    required this.label,
    required this.color,
    this.badge,
    this.subtitle,
  });

  final String label;
  final Color color;
  final String? badge;
  final String? subtitle;

  static _EventMeta of(final FnqEvent event) => switch (event) {
        NotificationQueued(:final notification) => _EventMeta(
            label: 'Queued',
            color: const Color(0xFF60A5FA), // blue-400
            badge: notification.queue.position.name,
            subtitle: notification.title ?? notification.message,
          ),
        NotificationDismissed(:final notification, :final reason) => _EventMeta(
            label: 'Dismissed',
            color: const Color(0xFF94A3B8), // slate-400
            badge: reason.name,
            subtitle: notification.title ?? notification.message,
          ),
        NotificationTapped(:final notification, :final behavior) => _EventMeta(
            label: 'Tapped',
            color: const Color(0xFF34D399), // emerald-400
            badge: behavior.runtimeType.toString(),
            subtitle: notification.title ?? notification.message,
          ),
        NotificationRelocated(:final from, :final to, :final notification) =>
          _EventMeta(
            label: 'Relocated',
            color: const Color(0xFFA78BFA), // violet-400
            badge: '${from.name} → ${to.name}',
            subtitle: notification.title ?? notification.message,
          ),
        NotificationReordered(:final notification, :final toIndex) =>
          _EventMeta(
            label: 'Reordered',
            color: const Color(0xFFFBBF24), // amber-400
            badge: 'index $toIndex',
            subtitle: notification.title ?? notification.message,
          ),
        QueueOverflowed(:final queue, :final dropped) => _EventMeta(
            label: 'Overflow',
            color: const Color(0xFFF87171), // red-400
            badge: queue.position.name,
            subtitle: dropped.title ?? dropped.message,
          ),
        NotificationSnoozed(:final notification, :final duration) => _EventMeta(
            label: 'Snoozed',
            color: const Color(0xFFFB7185), // rose-400
            badge: '${duration.inSeconds}s',
            subtitle: notification.title ?? notification.message,
          ),
        NotificationPinned(:final notification) => _EventMeta(
            label: 'Pinned',
            color: const Color(0xFFF59E0B), // amber-500
            badge: 'pinned',
            subtitle: notification.title ?? notification.message,
          ),
        NotificationUnpinned(:final notification) => _EventMeta(
            label: 'Unpinned',
            color: const Color(0xFF6B7280), // gray-500
            badge: 'unpinned',
            subtitle: notification.title ?? notification.message,
          ),
        NotificationCustomActionTriggered(
          :final notification,
          :final actionName,
        ) =>
            _EventMeta(
                label: 'Action',
                color: const Color(0xFF10B981), // emerald-500
                badge: actionName,
                subtitle: notification.title ?? notification.message,
              ),
      };
}

// ── Helpers ─────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sensors_outlined,
              size: 36,
              color: colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'Waiting for events…',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fire a scenario or tap a notification',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      );
}

// ── Data model ──────────────────────────────────────────────────────────────

class _LogEntry {
  const _LogEntry({required this.event, required this.time});

  final FnqEvent event;
  final DateTime time;
}
