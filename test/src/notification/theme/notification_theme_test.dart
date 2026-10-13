import 'package:flutter/material.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';
import 'package:flutter_notification_queue/src/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationThemeData', () {
    test('instantiates with specified tokens and color alias', () {
      const data = NotificationThemeData(
        color: Color(0xFF112233),
        backgroundColor: Color(0xFF445566),
        foregroundColor: Color(0xFF778899),
        borderColor: Color(0xFFAABBCC),
        shadowColor: Color(0xFF000000),
        titleTextStyle: TextStyle(fontSize: 16),
        messageTextStyle: TextStyle(fontSize: 14),
      );

      expect(data.accentColor, equals(const Color(0xFF112233)));
      expect(data.color, equals(const Color(0xFF112233)));
      expect(data.backgroundColor, equals(const Color(0xFF445566)));
      expect(data.foregroundColor, equals(const Color(0xFF778899)));
      expect(data.borderColor, equals(const Color(0xFFAABBCC)));
      expect(data.shadowColor, equals(const Color(0xFF000000)));
      expect(data.titleTextStyle?.fontSize, equals(16));
      expect(data.messageTextStyle?.fontSize, equals(14));
    });

    test('value equality and hashCode', () {
      const a = NotificationThemeData(
        accentColor: Color(0xFF123456),
        borderColor: Color(0xFFAABBCC),
      );
      const b = NotificationThemeData(
        accentColor: Color(0xFF123456),
        borderColor: Color(0xFFAABBCC),
      );
      const c = NotificationThemeData(
        accentColor: Color(0xFF654321),
        borderColor: Color(0xFFAABBCC),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith updates specified fields', () {
      const original = NotificationThemeData(
        accentColor: Color(0xFF111111),
        borderColor: Color(0xFF222222),
      );
      final updated = original.copyWith(
        accentColor: const Color(0xFF222222),
        backgroundColor: const Color(0xFF333333),
      );

      expect(updated.accentColor, equals(const Color(0xFF222222)));
      expect(updated.backgroundColor, equals(const Color(0xFF333333)));
      expect(updated.borderColor, equals(const Color(0xFF222222)));
    });

    test('merge overrides non-null properties from other', () {
      const base = NotificationThemeData(
        accentColor: Color(0xFF111111),
        backgroundColor: Color(0xFF222222),
        borderColor: Color(0xFF333333),
      );
      const patch = NotificationThemeData(
        backgroundColor: Color(0xFF999999),
        borderColor: Color(0xFF444444),
      );

      final merged = base.merge(patch);
      expect(merged.accentColor, equals(const Color(0xFF111111)));
      expect(merged.backgroundColor, equals(const Color(0xFF999999)));
      expect(merged.borderColor, equals(const Color(0xFF444444)));
      expect(base.merge(null), equals(base));
    });

    test('lerp interpolates between two instances', () {
      const a = NotificationThemeData(
        accentColor: Color(0xFF000000),
        borderColor: Color(0xFF000000),
      );
      const b = NotificationThemeData(
        accentColor: Color(0xFFFFFFFF),
        borderColor: Color(0xFFFFFFFF),
      );

      final mid = a.lerp(b, 0.5);
      expect(
        mid.accentColor,
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
      expect(normal.accentColor, equals(scheme.primary));
      expect(normal.backgroundColor, equals(scheme.surface));
      expect(normal.foregroundColor, equals(scheme.onSurface));

      final critical = NotificationThemeData.fromColorScheme(
        scheme,
        priority: NotificationPriority.critical,
      );
      expect(critical.accentColor, equals(scheme.error));
      expect(critical.backgroundColor, equals(scheme.errorContainer));
      expect(critical.foregroundColor, equals(scheme.onErrorContainer));

      final low = NotificationThemeData.fromColorScheme(
        scheme,
        priority: NotificationPriority.low,
      );
      expect(low.accentColor, equals(scheme.secondary));
      expect(low.backgroundColor, equals(scheme.surfaceContainerHighest));
    });

    test('fromSeed creates expected theme data', () {
      final data = NotificationThemeData.fromSeed(
        seedColor: Colors.amber,
        brightness: Brightness.dark,
      );
      expect(data.accentColor, isNotNull);
      expect(data.backgroundColor, isNotNull);
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

      expect(success.accentColor, equals(const Color(0xFF2D7512)));
      expect(
        error.accentColor,
        equals(Theme.of(buildContext).colorScheme.error),
      );
      expect(warning.accentColor, equals(const Color(0xFFC97725)));
      expect(info.accentColor, equals(const Color(0xFF51B4F9)));
    });
  });

  group('Hierarchical Theme & Style Cascade', () {
    testWidgets(
      'Notification accentColor overrides channel accentColor '
      'while keeping channel chromatic tokens',
      (final tester) async {
        late NotificationTheme resolved;
        const channelTheme = NotificationThemeData(
          accentColor: Color(0xFFFF0000),
          backgroundColor: Color(0xFF110000),
          foregroundColor: Color(0xFFFFEEEE),
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

        expect(resolved.color, equals(const Color(0xFF00FF00)));
        expect(resolved.backgroundColor, equals(const Color(0xFF110000)));
        expect(resolved.foregroundColor, equals(const Color(0xFFFFEEEE)));
      },
    );

    testWidgets(
      'Channel theme overrides ambient theme when notification has no theme',
      (final tester) async {
        late NotificationTheme resolved;
        const channelTheme = NotificationThemeData(
          accentColor: Color(0xFF123456),
          backgroundColor: Color(0xFF654321),
          foregroundColor: Color(0xFFABCDEF),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (final context) {
                final widget = NotificationWidget(
                  message: 'Test message',
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

        expect(resolved.color, equals(const Color(0xFF123456)));
        expect(resolved.backgroundColor, equals(const Color(0xFF654321)));
        expect(resolved.foregroundColor, equals(const Color(0xFFABCDEF)));
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
      'Deprecated loose colors fallback gracefully when theme is null',
      (final tester) async {
        late NotificationTheme resolved;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (final context) {
                // ignore: deprecated_member_use_from_same_package
                final widget = NotificationWidget(
                  message: 'Legacy colors test',
                  color: const Color(0xFF770077),
                  backgroundColor: const Color(0xFF220022),
                  foregroundColor: const Color(0xFFFF88FF),
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

        expect(resolved.color, equals(const Color(0xFF770077)));
        expect(resolved.backgroundColor, equals(const Color(0xFF220022)));
        expect(resolved.foregroundColor, equals(const Color(0xFFFF88FF)));
      },
    );

    testWidgets(
      'Picks up ambient ThemeData ThemeExtension when available',
      (final tester) async {
        late NotificationTheme resolved;
        const extensionTheme = NotificationThemeData(
          accentColor: Color(0xFF990099),
          backgroundColor: Color(0xFF330033),
          foregroundColor: Color(0xFFFFAAFF),
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
        expect(resolved.backgroundColor, equals(const Color(0xFF330033)));
        expect(resolved.foregroundColor, equals(const Color(0xFFFFAAFF)));
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
