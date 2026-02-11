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
    channels: const {
      NotificationChannel(
        name: 'scaffold',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.black,
      ),
      NotificationChannel(
        name: 'success',
        position: QueuePosition.topCenter,
        defaultDismissDuration: Duration(seconds: 3),
        defaultColor: Colors.green,
        defaultIcon: Icon(
          Icons.check_circle,
        ),
      ),
      NotificationChannel(
        name: 'scaffold.success',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.green,
        defaultIcon: Icon(
          Icons.check_circle,
        ),
      ),
      NotificationChannel(
        name: 'error',
        position: QueuePosition.topCenter,
        defaultDismissDuration: null,
        defaultColor: Colors.red,
        defaultIcon: Icon(
          Icons.error,
        ),
      ),
      NotificationChannel(
        name: 'scaffold.error',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.red,
        defaultIcon: Icon(
          Icons.error,
        ),
      ),
      NotificationChannel(
        name: 'info',
        position: QueuePosition.topCenter,
        defaultDismissDuration: Duration(seconds: 3),
        defaultColor: Colors.blue,
        defaultIcon: Icon(
          Icons.info,
        ),
      ),
      NotificationChannel(
        name: 'scaffold.info',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.blue,
        defaultIcon: Icon(
          Icons.info,
        ),
      ),
      NotificationChannel(
        name: 'warning',
        position: QueuePosition.topCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultColor: Colors.orange,
        defaultIcon: Icon(
          Icons.warning,
        ),
      ),
      NotificationChannel(
        name: 'scaffold.warning',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.orange,
        defaultIcon: Icon(
          Icons.warning,
        ),
      ),
      NotificationChannel(
        name: 'default',
        defaultColor: Colors.pink,
      ),
    },
    queues: {
      TopCenterQueue(
        margin: EdgeInsetsGeometry.zero,
        closeButtonBehavior: QueueCloseButtonBehavior.onHover,
        style: const FilledQueueStyle(),
        dragBehavior: const Disabled(),
        longPressDragBehavior: Relocate.to(
          {
            QueuePosition.centerRight,
            QueuePosition.centerLeft,
            QueuePosition.topCenter,
          },
        ),
      ),
      BottomCenterQueue(
        maxStackSize: 1,
        margin: EdgeInsetsGeometry.zero,
        style: const FlatQueueStyle(),
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
