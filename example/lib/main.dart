import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import 'demo_screen.dart';

void main() {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize global configuration for Notification Queue
  FlutterNotificationQueue.initialize(
    channels: {
      // 1. Add Standard Channels (success, error, warning, info)
      ...NotificationChannel.standardChannels(
        position: QueuePosition.topCenter,
        defaultDismissDuration: null,
      ),

      // 2. Add Custom Channels
      const NotificationChannel(
        name: 'scaffold',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.black,
      ),
      NotificationChannel.defaultChannel(
        defaultDismissDuration: const Duration(
          seconds: 5,
        ),
      ),
    },
    queues: {
      // 1. Use Default Queue for TopCenter
      TopCenterQueue(
        margin: EdgeInsetsGeometry.zero,
        spacing: 8.0,
        style: const FilledQueueStyle(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          opacity: 0.7,
          elevation: 8,
        ),
        closeButtonBehavior: const VisibleOnHover(),
        dragBehavior: const Dismiss(
          zones: DismissZone.naturalDirection,
        ),
        longPressDragBehavior: Reorder(),
        // longPressDragBehavior: Relocate.to(
        //   {
        //     QueuePosition.centerRight,
        //     QueuePosition.centerLeft,
        //     QueuePosition.bottomLeft,
        //     QueuePosition.bottomRight,
        //   },
        // ),
        transition: const ScaleTransitionStrategy(),
      ),

      // 2. Custom Queue Configuration for BottomCenter
      BottomCenterQueue(
        maxStackSize: 1,
        margin: EdgeInsetsGeometry.zero,
        style: const FlatQueueStyle(),
        transition: const SlideTransitionStrategy(),
        dragBehavior: const Dismiss(zones: DismissZone.naturalDirection),
        longPressDragBehavior: Relocate.to(
          {
            QueuePosition.topLeft,
          },
        ),
      ),
    },
  );

  FlutterNativeSplash.remove();

  runApp(const NotificationQueueExample());
}

class NotificationQueueExample extends StatefulWidget {
  const NotificationQueueExample({super.key});

  static NotificationQueueExampleState? of(final BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<
              InheritedNotificationQueueExample>()
          ?.state;

  @override
  State<NotificationQueueExample> createState() =>
      NotificationQueueExampleState();
}

class NotificationQueueExampleState extends State<NotificationQueueExample> {
  var themeMode = ThemeMode.light;

  void toggleTheme() {
    void rebuild(final Element el) {
      el
        ..markNeedsBuild()
        ..visitChildren(rebuild);
    }

    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    (context as Element).visitChildren(rebuild);

    setState(() {});
  }

  @override
  Widget build(final BuildContext context) => InheritedNotificationQueueExample(
        state: this,
        // Use the builder pattern to wrap the entire app correctly
        child: MaterialApp(
          builder: FlutterNotificationQueue.builder,
          title: 'NotificationQueue Example',
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeMode,
          home: const DemoScreen(),
        ),
      );
}

class InheritedNotificationQueueExample extends InheritedWidget {
  const InheritedNotificationQueueExample({
    required super.child,
    required this.state,
    super.key,
  });

  final NotificationQueueExampleState state;

  @override
  bool updateShouldNotify(
    covariant final InheritedNotificationQueueExample oldWidget,
  ) =>
      oldWidget.state != state;
}
