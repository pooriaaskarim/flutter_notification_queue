import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../models/channel_setup.dart';
import '../models/queue_setup.dart';
import '../models/studio_setup.dart';

// ── Events ──

sealed class SetupEvent {
  const SetupEvent();
}

// Queue CRUD
final class AddQueue extends SetupEvent {
  const AddQueue(this.position, [this.setup = const QueueSetup()]);
  final QueuePosition position;
  final QueueSetup setup;
}

final class RemoveQueue extends SetupEvent {
  const RemoveQueue(this.position);
  final QueuePosition position;
}

final class UpdateQueue extends SetupEvent {
  const UpdateQueue(this.position, this.setup);
  final QueuePosition position;
  final QueueSetup setup;
}

// Channel CRUD
final class AddChannel extends SetupEvent {
  const AddChannel(this.setup);
  final ChannelSetup setup;
}

final class RemoveChannel extends SetupEvent {
  const RemoveChannel(this.name);
  final String name;
}

final class UpdateChannel extends SetupEvent {
  const UpdateChannel(this.name, this.setup);
  final String name;
  final ChannelSetup setup;
}

final class AddStandardPresets extends SetupEvent {
  const AddStandardPresets();
}

// Navigation
final class SelectActiveQueue extends SetupEvent {
  const SelectActiveQueue(this.position);
  final QueuePosition position;
}

// Bulk
final class ApplySetup extends SetupEvent {
  const ApplySetup(this.setup);
  final StudioSetup setup;
}

final class ResetSetup extends SetupEvent {
  const ResetSetup();
}

// ── State ──

class SetupState {
  const SetupState({
    required this.setup,
    this.activeQueuePosition = QueuePosition.topCenter,
  });

  final StudioSetup setup;

  /// Which queue is currently being edited in the configurator.
  final QueuePosition activeQueuePosition;

  /// Convenience: the currently-active queue setup.
  QueueSetup? get activeQueue => setup.queues[activeQueuePosition];

  SetupState copyWith({
    final StudioSetup? setup,
    final QueuePosition? activeQueuePosition,
  }) =>
      SetupState(
        setup: setup ?? this.setup,
        activeQueuePosition: activeQueuePosition ?? this.activeQueuePosition,
      );
}

// ── Bloc ──

/// Manages the [StudioSetup] lifecycle.
///
/// Reactively calls [FlutterNotificationQueue.configure] whenever
/// the setup actually changes, via the [onChange] hook.
class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc() : super(SetupState(setup: StudioSetup.withDefaults())) {
    // Queue CRUD
    on<AddQueue>((final event, final emit) {
      final queues = Map<QueuePosition, QueueSetup>.from(state.setup.queues);
      queues[event.position] = event.setup;
      emit(
        state.copyWith(
          setup: _maintainRelocationInvariants(
            state.setup.copyWith(queues: queues),
          ),
          activeQueuePosition: event.position,
        ),
      );
    });

    on<RemoveQueue>((final event, final emit) {
      final queues = Map<QueuePosition, QueueSetup>.from(state.setup.queues)
        ..remove(event.position);
      if (queues.isEmpty) {
        return; // must have at least one queue
      }
      final newActive = state.activeQueuePosition == event.position
          ? queues.keys.first
          : state.activeQueuePosition;
      emit(
        state.copyWith(
          setup: state.setup.copyWith(queues: queues),
          activeQueuePosition: newActive,
        ),
      );
    });

    on<UpdateQueue>((final event, final emit) {
      final queues = Map<QueuePosition, QueueSetup>.from(state.setup.queues);
      queues[event.position] = event.setup;
      emit(
        state.copyWith(
          setup: _maintainRelocationInvariants(
            state.setup.copyWith(queues: queues),
            priorityOwner: event.position,
          ),
        ),
      );
    });

    // Channel CRUD
    on<AddChannel>((final event, final emit) {
      final channels = Map<String, ChannelSetup>.from(state.setup.channels);
      channels[event.setup.name] = event.setup;
      emit(state.copyWith(setup: state.setup.copyWith(channels: channels)));
    });

    on<RemoveChannel>((final event, final emit) {
      final channels = Map<String, ChannelSetup>.from(state.setup.channels)
        ..remove(event.name);
      emit(state.copyWith(setup: state.setup.copyWith(channels: channels)));
    });

    on<UpdateChannel>((final event, final emit) {
      final channels = Map<String, ChannelSetup>.from(state.setup.channels);
      channels[event.name] = event.setup;
      emit(state.copyWith(setup: state.setup.copyWith(channels: channels)));
    });

    on<AddStandardPresets>((final event, final emit) {
      final newChannels = Map<String, ChannelSetup>.from(state.setup.channels)
        ..addAll(ChannelSetup.standardChannels());
      emit(state.copyWith(setup: state.setup.copyWith(channels: newChannels)));
    });

    // Navigation
    on<SelectActiveQueue>((final event, final emit) {
      emit(state.copyWith(activeQueuePosition: event.position));
    });

    // Bulk
    on<ApplySetup>((final event, final emit) {
      emit(state.copyWith(setup: event.setup));
    });

    on<ResetSetup>((final event, final emit) {
      emit(SetupState(setup: StudioSetup.withDefaults()));
    });

    // Apply initial configuration.
    _applyToLibrary(state.setup);
  }

  StudioSetup? _lastAppliedSetup;

  @override
  void onChange(final Change<SetupState> change) {
    super.onChange(change);
    final newSetup = change.nextState.setup;
    if (newSetup != _lastAppliedSetup) {
      _applyToLibrary(newSetup);
    }
  }

  void _applyToLibrary(final StudioSetup setup) {
    FlutterNotificationQueue.configure(
      queues: setup.toLibraryQueues(),
      channels: setup.toLibraryChannels(),
    );
    _lastAppliedSetup = setup;
    debugPrint(
      '[SetupBloc] Applied: '
      '${setup.queues.length} queues, '
      '${setup.channels.length} channels',
    );
  }

  /// Enforces NFQ library constraints and business rules on the setup.
  ///
  /// This method is responsible for:
  /// 1.  **Removing Masters from Slaves**: A position cannot be a relocation
  ///     target if it also hosts a Master queue.
  /// 2.  **Maintaining Disjoint Groups**: If [priorityOwner] is specified, its
  ///     relocation targets are preserved, and any overlapping targets are
  ///     removed from other queues to ensure strict group isolation.
  StudioSetup _maintainRelocationInvariants(
    final StudioSetup setup, {
    final QueuePosition? priorityOwner,
  }) {
    final activePositions = setup.queues.keys.toSet();
    final updatedQueues = <QueuePosition, QueueSetup>{...setup.queues};

    // 1. Initial prune: Targets cannot be Master (active) queues.
    for (final entry in updatedQueues.entries) {
      final pos = entry.key;
      final q = entry.value;
      final valid =
          q.relocateTargets.where((final p) => !activePositions.contains(p));
      updatedQueues[pos] = q.copyWith(relocateTargets: valid.toSet());
    }

    // 2. Strict Isolation: Each Slave belongs to at most one Master.
    // The 'priorityOwner' (the one just edited) keeps its targets; others lose
    // overlapping positions to maintain group integrity.
    if (priorityOwner != null) {
      final priorityTargets = updatedQueues[priorityOwner]?.relocateTargets;
      if (priorityTargets != null) {
        for (final pos in updatedQueues.keys) {
          if (pos == priorityOwner) {
            continue;
          }
          final q = updatedQueues[pos]!;
          final filtered = q.relocateTargets
              .where((final t) => !priorityTargets.contains(t))
              .toSet();
          if (filtered.length != q.relocateTargets.length) {
            updatedQueues[pos] = q.copyWith(relocateTargets: filtered);
          }
        }
      }
    }

    return setup.copyWith(queues: updatedQueues);
  }
}
