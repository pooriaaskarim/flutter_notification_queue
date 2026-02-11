// lib/src/overlay_manager/overlay_manager.dart
import 'package:flutter/material.dart';

import '../../utils/logger.dart';

part 'overlay_position.dart';

part 'overlay_entry_data.dart';

class _ActiveIdentifiersNotifier extends ValueNotifier<List<String>> {
  _ActiveIdentifiersNotifier() : super([]);

  void update() {
    notifyListeners();
  }
}

class OverlayManager {
  OverlayManager._()
      : assert(
            initialized,
            'NotificationQueue:'
            '\n OverlayManager must be initialized before use.'
            '\n Please wrap your root widget inside a'
            ' NotificationQueueWrapper first.');

  static bool initialized = false;
  static final OverlayManager instance = OverlayManager._();

  final Map<String, OverlayEntryData> _entries = {};
  final _activeIdentifiersNotifier = _ActiveIdentifiersNotifier();
  OverlayEntry? _rootEntry;
  static late BuildContext _rootContext; // Set in init

  // --------------------------------------------------------------------- //
  //  INITIALIZE
  // --------------------------------------------------------------------- //
  static void configure(final BuildContext rootContext) {
    final b = LogBuffer.d;
    if (!initialized) {
      b?.writeAll(['Initializing... .']);

      initialized = true;
    }
    b
      ?..writeAll(['RootContext: $rootContext'])
      ..flush();
    _rootContext = rootContext;
  }

  // --------------------------------------------------------------------- //
  //  SHOW
  // --------------------------------------------------------------------- //
  void show(final String identifier, final OverlayEntryData data) {
    final b = LogBuffer.d
      ?..writeAll([
        'identifier: $identifier',
        'data.builder: ${data.builder}',
        'data.position: ${data.position}',
        'data.priority: ${data.priority}',
        'data.entryDuration: ${data.entryDuration}',
        'data.exitDuration: ${data.exitDuration}',
        'data.entryCurve: ${data.entryCurve}',
        'data.exitCurve: ${data.exitCurve}',
        'data.maintainState: ${data.maintainState}',
      ]);

    if (_entries.containsKey(identifier)) {
      b?.writeAll(['Entry Already Exists,', '----> Updating... .']);

      update(identifier, data);
      return;
    }

    _entries[identifier] = data..stateKey = GlobalKey();
    _updateActiveIdentifiers();
    data.onShow?.call();

    if (_rootEntry == null) {
      b?.writeAll(['No Root Entry,', '----> Inserting... .']);

      _insertRootEntry();
    }

    _activeIdentifiersNotifier.update();
  }

  // --------------------------------------------------------------------- //
  //  HIDE
  // --------------------------------------------------------------------- //
  void hide(final String identifier) {
    final b = LogBuffer.d
      ?..writeAll([
        'Hiding Identifier: $identifier',
      ]);

    final removed = _entries.remove(identifier);
    if (removed == null) {
      b
        ?..writeAll(['No Entry Found For Identifier,', '----> Skipped Hiding.'])
        ..flush();

      return;
    }

    b?.writeAll([
      'Removing Entry... .',
      'Calling onHide callback... .',
    ]);

    removed.onHide?.call();

    _updateActiveIdentifiers();
    _activeIdentifiersNotifier.update();

    if (_entries.isEmpty) {
      b?.writeAll(['No more entries,', '----> Removing root entry... .']);

      _removeRootEntry();
    }
    b?.flush();
  }

  // --------------------------------------------------------------------- //
  //  UPDATE
  // --------------------------------------------------------------------- //
  void update(final String identifier, final OverlayEntryData newData) {
    final b = LogBuffer.d
      ?..writeAll([
        'identifier: $identifier',
        'NewData/Builder: ${newData.builder}',
        'NewData/Position: ${newData.position}',
        'NewData/Priority: ${newData.priority}',
      ]);

    if (_entries.containsKey(identifier)) {
      _entries[identifier] = newData;
      b?.writeAll(['Entry Updated,', '----> Marking Root Entry For Rebuild.']);

      _rootEntry?.markNeedsBuild();
    } else {
      b?.writeAll(['No Entry Found For Identifier,', '----> Skipped Update.']);
    }
    b?.flush();
  }

  // --------------------------------------------------------------------- //
  //  INSERT ROOT ENTRY
  // --------------------------------------------------------------------- //
  void _insertRootEntry() {
    final b = LogBuffer.d;
    _rootEntry = OverlayEntry(
      builder: (final context) {
        b?.writeAll([
          'Building root overlay (Stack with ${_entries.length} children)',
        ]);

        return ValueListenableBuilder<List<String>>(
          valueListenable: _activeIdentifiersNotifier,
          builder: (final context, final activeIdentifiers, final _) {
            b?.writeAll([
              'ValueListenableBuilder rebuild',
              'activeIdentifiers: $activeIdentifiers',
            ]);
            b?.flush();
            return Stack(
              children: activeIdentifiers.map((final identifier) {
                final data = _entries[identifier]!;
                b
                  ?..writeAll([
                    'identifier: $identifier',
                    'data.position: ${data.position}',
                    'data.priority: ${data.priority}',
                  ])
                  ..flush();
                Widget content = KeyedSubtree(
                  key: data.stateKey,
                  child: data.builder(context),
                );

                // AnimatedSwitcher
                content = AnimatedSwitcher(
                  duration: data.entryDuration ?? Duration.zero,
                  reverseDuration: data.exitDuration,
                  switchInCurve: data.entryCurve,
                  switchOutCurve: data.exitCurve,
                  child: content,
                );

                // Position
                return switch (data.position) {
                  AbsolutePosition(:final offset) => Positioned(
                      left: offset.dx,
                      top: offset.dy,
                      child: content,
                    ),
                  AlignedPosition(:final alignment) => Align(
                      alignment: alignment,
                      child: content,
                    ),
                  AnchoredPosition(
                    :final anchorKey,
                    :final followerAlignment,
                    :final targetAlignment
                  ) =>
                    _buildAnchored(
                      context,
                      anchorKey,
                      content,
                      followerAlignment,
                      targetAlignment,
                    ),
                };
              }).toList(),
            );
          },
        );
      },
      maintainState: true,
      opaque: false,
    );

    b
      ?..writeAll(['Inserting root entry into Overlay'])
      ..flush();

    Overlay.of(_rootContext).insert(_rootEntry!);
  }

  // --------------------------------------------------------------------- //
  //  REMOVE ROOT ENTRY
  // --------------------------------------------------------------------- //
  void _removeRootEntry() {
    _rootEntry?.remove();
    _rootEntry = null;

    final b = LogBuffer.d
      ?..writeAll(['Root Entry Removed'])
      ..flush();
  }

  // --------------------------------------------------------------------- //
  //  UPDATE ACTIVE IDENTIFIERS (priority sort)
  // --------------------------------------------------------------------- //
  void _updateActiveIdentifiers() {
    final b = LogBuffer.d
      ?..writeAll(['Current Entries Cound: ${_entries.length}']);

    final sorted = _entries.keys.toList()
      ..sort((final a, final b) =>
          _entries[a]!.priority.compareTo(_entries[b]!.priority));

    b?.writeAll(['Sorted Identifires: $sorted']);

    _activeIdentifiersNotifier.value = sorted;
    b?.flush();
  }

  // --------------------------------------------------------------------- //
  //  BUILD ANCHORED WIDGET
  // --------------------------------------------------------------------- //
  Widget _buildAnchored(
    final BuildContext context,
    final GlobalKey anchorKey,
    final Widget content,
    final Alignment followerAlignment,
    final Alignment targetAlignment,
  ) {
    final b = LogBuffer.d
      ?..writeAll([
        'Anchor Key: $anchorKey',
        'Follower Alignment: $followerAlignment',
        'Target Alignment: $targetAlignment'
      ]);

    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      b?.writeAll([
        'Anchor RenderBox not found.',
        '----> Returning Empty Widget',
      ]);
      return const SizedBox.shrink();
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    b
      ?..writeAll([
        'Anchor Global Position: $position',
        'Anchor Size: $size',
      ])
      ..flush();

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: size.width,
      height: size.height,
      child: Align(alignment: followerAlignment, child: content),
    );
  }

  // --------------------------------------------------------------------- //
  //  DISPOSE
  // --------------------------------------------------------------------- //
  void dispose() {
    _entries.clear();
    _activeIdentifiersNotifier.value = [];
    _removeRootEntry();
    final b = LogBuffer.d
      ?..writeAll(['Disposed OverlayManager.'])
      ..flush();
  }
}
