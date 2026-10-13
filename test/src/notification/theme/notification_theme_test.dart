import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationThemeData', () {
    test('instantiates with specified tokens', () {
      const data = NotificationThemeData(
        color: Color(0xFF112233),
        shadowColor: Color(0xFF000000),
        titleTextStyle: TextStyle(fontSize: 16),
        messageTextStyle: TextStyle(fontSize: 14),
      );

      expect(data.color, equals(const Color(0xFF112233)));
      expect(data.shadowColor, equals(const Color(0xFF000000)));
      expect(data.titleTextStyle?.fontSize, equals(16));
      expect(data.messageTextStyle?.fontSize, equals(14));
    });

    test('value equality and hashCode', () {
      const a = NotificationThemeData(
        color: Color(0xFF123456),
        shadowColor: Color(0xFF000000),
      );
      const b = NotificationThemeData(
        color: Color(0xFF123456),
        shadowColor: Color(0xFF000000),
      );
      const c = NotificationThemeData(
        color: Color(0xFF654321),
        shadowColor: Color(0xFF000000),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith updates specified fields', () {
      const original = NotificationThemeData(
        color: Color(0xFF111111),
        shadowColor: Color(0xFF222222),
      );
      final updated = original.copyWith(
        color: const Color(0xFF333333),
      );

      expect(updated.color, equals(const Color(0xFF333333)));
      expect(updated.shadowColor, equals(const Color(0xFF222222)));
    });

    test('merge overrides non-null properties from other', () {
      const base = NotificationThemeData(
        color: Color(0xFF111111),
        shadowColor: Color(0xFF222222),
      );
      const patch = NotificationThemeData(
        shadowColor: Color(0xFF444444),
      );

      final merged = base.merge(patch);
      expect(merged.color, equals(const Color(0xFF111111)));
      expect(merged.shadowColor, equals(const Color(0xFF444444)));
      expect(base.merge(null), equals(base));
    });

    test('lerp interpolates between two instances', () {
      const a = NotificationThemeData(
        color: Color(0xFF000000),
      );
      const b = NotificationThemeData(
        color: Color(0xFFFFFFFF),
      );

      final mid = a.lerp(b, 0.5);
      expect(
        mid.color,
        equals(
          Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
        ),
      );
      expect(a.lerp(null, 0.5), equals(a));
    });

    test('fromColorScheme derives tokens for different priorities', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

      final normal = NotificationThemeData.fromColorScheme(
        scheme,
        priority: NotificationPriority.normal,
      );
      expect(normal.color, equals(scheme.primary));

      final critical = NotificationThemeData.fromColorScheme(
        scheme,
        priority: NotificationPriority.critical,
      );
      expect(critical.color, equals(scheme.error));

      final low = NotificationThemeData.fromColorScheme(
        scheme,
        priority: NotificationPriority.low,
      );
      expect(low.color, equals(scheme.secondary));
    });

    test('fromSeed creates expected theme data', () {
      final data = NotificationThemeData.fromSeed(
        seedColor: Colors.amber,
        brightness: Brightness.dark,
      );
      expect(data.color, isNotNull);
    });

    testWidgets('semantic factories build contextual palettes', (
      final tester,
    ) async {
      late BuildContext buildContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (final context) {
              buildContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final success = NotificationThemeData.success(buildContext);
      final error = NotificationThemeData.error(buildContext);
      final warning = NotificationThemeData.warning(buildContext);
      final info = NotificationThemeData.info(buildContext);

      expect(success.color, equals(const Color(0xFF2D7512)));
      expect(
        error.color,
        equals(Theme.of(buildContext).colorScheme.error),
      );
      expect(warning.color, equals(const Color(0xFFC97725)));
      expect(info.color, equals(const Color(0xFF51B4F9)));
    });
  });

  group('Hierarchical Theme & Style Cascade', () {
    testWidgets(
      'Notification color overrides channel color in Flat style',
      (final tester) async {
        late NotificationTheme resolved;
        const channelTheme = NotificationThemeData(
          color: Color(0xFFFF0000),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (final context) {
                final widget = NotificationWidget(
                  message: 'Test message',
                  accentColor: const Color(0xFF00FF00),
                  configuration: ConfigurationManager(
                    queues: {const NotificationQueue()},
                    channels: {
                      const NotificationChannel(
                        name: 'default',
                        theme: channelTheme,
                      ),
                    },
                  ),
                );

                resolved = NotificationTheme.resolveWith(
                  context,
                  const FlatQueueStyle(),
                  widget,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        final colorScheme =
            Theme.of(tester.element(find.byType(SizedBox))).colorScheme;
        expect(resolved.color, equals(const Color(0xFF00FF00)));
        expect(resolved.backgroundColor, equals(colorScheme.surface));
        expect(resolved.foregroundColor, equals(colorScheme.onSurface));
      },
    );

    testWidgets(
      'Filled style fills card body and computes contrast foreground',
      (final tester) async {
        late NotificationTheme resolved;
        const channelTheme = NotificationThemeData(
          color: Color(0xFF2D7512), // Dark green
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (final context) {
                final widget = NotificationWidget(
                  message: 'Filled test',
                  configuration: ConfigurationManager(
                    queues: {const NotificationQueue()},
                    channels: {
                      const NotificationChannel(
                        name: 'default',
                        theme: channelTheme,
                      ),
                    },
                  ),
                );

                resolved = NotificationTheme.resolveWith(
                  context,
                  const FilledQueueStyle(),
                  widget,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        expect(resolved.color, equals(const Color(0xFF2D7512)));
        expect(resolved.backgroundColor, equals(const Color(0xFF2D7512)));
        // Dark green has luminance < 0.5, so foreground should be white
        expect(resolved.foregroundColor, equals(Colors.white));
      },
    );

    testWidgets(
      'Outlined style uses ambient surface/onSurface and strokes border with color',
      (final tester) async {
        late NotificationTheme resolved;
        const channelTheme = NotificationThemeData(
          color: Color(0xFF0000FF),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (final context) {
                final widget = NotificationWidget(
                  message: 'Outlined test',
                  configuration: ConfigurationManager(
                    queues: {const NotificationQueue()},
                    channels: {
                      const NotificationChannel(
                        name: 'default',
                        theme: channelTheme,
                      ),
                    },
                  ),
                );

                resolved = NotificationTheme.resolveWith(
                  context,
                  const OutlinedQueueStyle(),
                  widget,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        expect(resolved.color, equals(const Color(0xFF0000FF)));
        final colorScheme =
            Theme.of(tester.element(find.byType(SizedBox))).colorScheme;
        expect(resolved.backgroundColor, equals(colorScheme.surface));
        expect(resolved.foregroundColor, equals(colorScheme.onSurface));
        expect(resolved.shape, isA<RoundedRectangleBorder>());
        final shape = resolved.shape! as RoundedRectangleBorder;
        expect(shape.side.color, equals(const Color(0xFF0000FF)));
      },
    );

    testWidgets(
      'Queue style archetype governs physical shape and geometry',
      (final tester) async {
        late NotificationTheme resolved;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (final context) {
                final widget = NotificationWidget(
                  message: 'Outlined test',
                  configuration: ConfigurationManager(
                    queues: {
                      const NotificationQueue(
                        style: OutlinedQueueStyle(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          elevation: 5.0,
                          padding: EdgeInsets.all(12),
                          borderWidth: 2.5,
                        ),
                      ),
                    },
                    channels: {
                      const NotificationChannel(name: 'default'),
                    },
                  ),
                );

                resolved = NotificationTheme.resolveWith(
                  context,
                  widget.queue.style,
                  widget,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        expect(
          resolved.borderRadius,
          equals(const BorderRadius.all(Radius.circular(16))),
        );
        expect(resolved.elevation, equals(5.0));
        expect(resolved.padding, equals(const EdgeInsets.all(12)));
        expect(resolved.borderWidth, equals(2.5));
        expect(resolved.shape, isA<RoundedRectangleBorder>());
      },
    );

    testWidgets(
      'Picks up ambient ThemeData ThemeExtension when available',
      (final tester) async {
        late NotificationTheme resolved;
        const extensionTheme = NotificationThemeData(
          color: Color(0xFF990099),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: const [extensionTheme],
            ),
            home: Builder(
              builder: (final context) {
                final widget = NotificationWidget(
                  message: 'Extension test',
                  configuration: ConfigurationManager(
                    queues: {const NotificationQueue()},
                    channels: {
                      const NotificationChannel(name: 'default'),
                    },
                  ),
                );

                resolved = NotificationTheme.resolveWith(
                  context,
                  const FlatQueueStyle(),
                  widget,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        expect(resolved.color, equals(const Color(0xFF990099)));
      },
    );

    testWidgets(
      'Typography and iconTheme propagate through channel theme to '
      'NotificationTheme',
      (final tester) async {
        late NotificationTheme resolved;
        const customTheme = NotificationThemeData(
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          messageTextStyle:
              TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
          iconTheme: IconThemeData(color: Color(0xFF118833), size: 30),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (final context) {
                final widget = NotificationWidget(
                  message: 'Typography test',
                  configuration: ConfigurationManager(
                    queues: {const NotificationQueue()},
                    channels: {
                      const NotificationChannel(
                        name: 'default',
                        theme: customTheme,
                      ),
                    },
                  ),
                );

                resolved = NotificationTheme.resolveWith(
                  context,
                  const FlatQueueStyle(),
                  widget,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        expect(resolved.titleTextStyle?.fontSize, equals(22));
        expect(resolved.titleTextStyle?.fontWeight, equals(FontWeight.w900));
        expect(resolved.messageTextStyle?.fontSize, equals(15));
        expect(resolved.messageTextStyle?.fontStyle, equals(FontStyle.italic));
        expect(resolved.iconTheme?.color, equals(const Color(0xFF118833)));
        expect(resolved.iconTheme?.size, equals(30));
      },
    );
  });
}
