// lib/src/overlay_manager/overlay_manager.dart
import 'package:flutter/material.dart';

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
    debugPrint('''
--OverlayManager:::configure--    ''');
    if (!initialized) {
      debugPrint('''
----|Initializing...''');
      initialized = true;
    }
    debugPrint('''
----|rootContext: $rootContext
''');
    _rootContext = rootContext;
  }

  // --------------------------------------------------------------------- //
  //  SHOW
  // --------------------------------------------------------------------- //
  void show(final String identifier, final OverlayEntryData data) {
    debugPrint('''
--OverlayManager:::show--
----|identifier: $identifier
----|data.builder: ${data.builder}
----|data.position: ${data.position}
----|data.priority: ${data.priority}
----|data.entryDuration: ${data.entryDuration}
----|data.exitDuration: ${data.exitDuration}
----|data.entryCurve: ${data.entryCurve}
----|data.exitCurve: ${data.exitCurve}
----|data.maintainState: ${data.maintainState}
''');

    if (_entries.containsKey(identifier)) {
      debugPrint('''
----|Entry already exists → calling update()
''');
      update(identifier, data);
      return;
    }

    _entries[identifier] = data..stateKey = GlobalKey();
    _updateActiveIdentifiers();
    data.onShow?.call();

    if (_rootEntry == null) {
      debugPrint('''
----|No root entry → inserting _rootEntry
''');
      _insertRootEntry();
    }

    _activeIdentifiersNotifier.update();
  }

  // --------------------------------------------------------------------- //
  //  HIDE
  // --------------------------------------------------------------------- //
  void hide(final String identifier) {
    debugPrint('''
--OverlayManager:::hide--
----|identifier: $identifier
''');

    final data = _entries.remove(identifier);
    if (data == null) {
      debugPrint('''
----|No entry found for identifier → nothing to hide
''');
      return;
    }

    debugPrint('''
----|Removed entry
----|Calling onHide callback
''');
    data.onHide?.call();

    _updateActiveIdentifiers();
    _activeIdentifiersNotifier.update();

    if (_entries.isEmpty) {
      debugPrint('''
----|No more entries → removing root entry
''');
      _removeRootEntry();
    }
  }

  // --------------------------------------------------------------------- //
  //  UPDATE
  // --------------------------------------------------------------------- //
  void update(final String identifier, final OverlayEntryData newData) {
    debugPrint('''
--OverlayManager:::update--
----|identifier: $identifier
----|newData.builder: ${newData.builder}
----|newData.position: ${newData.position}
----|newData.priority: ${newData.priority}
''');

    if (_entries.containsKey(identifier)) {
      _entries[identifier] = newData;
      debugPrint('''
----|Entry updated → marking root entry for rebuild
''');
      _rootEntry?.markNeedsBuild();
    } else {
      debugPrint('''
----|No entry for identifier → ignoring update
''');
    }
  }

  // --------------------------------------------------------------------- //
  //  INSERT ROOT ENTRY
  // --------------------------------------------------------------------- //
  void _insertRootEntry() {
    debugPrint('''
--OverlayManager::_insertRootEntry--
''');

    _rootEntry = OverlayEntry(
      builder: (final context) {
        debugPrint('''
----|Building root overlay (Stack with ${_entries.length} children)
''');
        return ValueListenableBuilder<List<String>>(
          valueListenable: _activeIdentifiersNotifier,
          builder: (final context, final activeIdentifiers, final _) {
            debugPrint('''
----|ValueListenableBuilder rebuild
----|activeIdentifiers: $activeIdentifiers
''');
            return Stack(
              children: activeIdentifiers.map((final identifier) {
                final data = _entries[identifier]!;
                debugPrint('''
----|Rendering child
----|  identifier: $identifier
----|  priority: ${data.priority}
----|  position: ${data.position}
''');

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

    debugPrint('''
----|Inserting root entry into Overlay
''');
    Overlay.of(_rootContext).insert(_rootEntry!);
  }

  // --------------------------------------------------------------------- //
  //  REMOVE ROOT ENTRY
  // --------------------------------------------------------------------- //
  void _removeRootEntry() {
    debugPrint('''
--OverlayManager::_removeRootEntry--
''');

    _rootEntry?.remove();
    _rootEntry = null;
    debugPrint('''
----|Root entry removed
''');
  }

  // --------------------------------------------------------------------- //
  //  UPDATE ACTIVE IDENTIFIERS (priority sort)
  // --------------------------------------------------------------------- //
  void _updateActiveIdentifiers() {
    debugPrint('''
--OverlayManager::_updateActiveIdentifiers--
----|Current entries count: ${_entries.length}
''');

    final sorted = _entries.keys.toList()
      ..sort((final a, final b) =>
          _entries[a]!.priority.compareTo(_entries[b]!.priority));

    debugPrint('''
----|Sorted identifiers: $sorted
''');

    _activeIdentifiersNotifier.value = sorted;
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
    debugPrint('''
--OverlayManager::_buildAnchored--
----|anchorKey: $anchorKey
----|followerAlignment: $followerAlignment
----|targetAlignment: $targetAlignment
''');

    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint('''
----|Anchor RenderBox not found → returning SizedBox.shrink()
''');
      return const SizedBox.shrink();
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    debugPrint('''
----|Anchor global position: $position
----|Anchor size: $size
''');

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
    debugPrint('''
--OverlayManager:::dispose--
----|Clearing ${_entries.length} entries
''');

    _entries.clear();
    _activeIdentifiersNotifier.value = [];
    _removeRootEntry();

    debugPrint('''
----|OverlayManager fully disposed
''');
  }
}
