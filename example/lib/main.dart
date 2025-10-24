import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import 'demo_screen.dart';

void main() {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  FlutterNativeSplash.remove();

  NotificationManager.initialize(
    channels: {
      const NotificationChannel(
        name: 'scaffold',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.black,
        enabled: false,
      ),
      const NotificationChannel(
        name: 'success',
        position: QueuePosition.topCenter,
        defaultDismissDuration: Duration(seconds: 3),
        defaultColor: Colors.green,
        defaultIcon: Icon(
          Icons.check_circle,
        ),
      ),
      const NotificationChannel(
        name: 'scaffold.success',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.green,
        defaultIcon: Icon(
          Icons.check_circle,
        ),
        enabled: false,
      ),
      const NotificationChannel(
        name: 'error',
        position: QueuePosition.topCenter,
        defaultDismissDuration: null,
        defaultColor: Colors.red,
        defaultIcon: Icon(
          Icons.error,
        ),
      ),
      const NotificationChannel(
        name: 'scaffold.error',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.red,
        defaultIcon: Icon(
          Icons.error,
        ),
        enabled: false,
      ),
      const NotificationChannel(
        name: 'info',
        position: QueuePosition.topCenter,
        defaultDismissDuration: Duration(seconds: 3),
        defaultColor: Colors.blue,
        defaultIcon: Icon(
          Icons.info,
        ),
      ),
      const NotificationChannel(
        name: 'scaffold.info',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.blue,
        defaultIcon: Icon(
          Icons.info,
        ),
        enabled: false,
      ),
      const NotificationChannel(
        name: 'warning',
        position: QueuePosition.topCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultColor: Colors.orange,
        defaultIcon: Icon(
          Icons.warning,
        ),
      ),
      const NotificationChannel(
        name: 'scaffold.warning',
        position: QueuePosition.bottomCenter,
        defaultDismissDuration: Duration(seconds: 5),
        defaultBackgroundColor: Colors.black,
        defaultForegroundColor: Colors.white,
        defaultColor: Colors.orange,
        defaultIcon: Icon(
          Icons.warning,
        ),
        enabled: false,
      ),
      const NotificationChannel(
        name: 'default',
        defaultColor: Colors.pink,
      ),
    },
    queues: {
      TopCenterQueue(
        margin: EdgeInsetsGeometry.zero,
        closeButtonBehaviour: QueueCloseButtonBehaviour.onHover,
        style: const FilledQueueStyle(),
        dragBehaviour: const DisabledDragBehaviour(),
        longPressDragBehaviour: RelocateLongPressDragBehaviour(
          positions: {
            QueuePosition.centerRight,
            QueuePosition.centerLeft,
          },
        ),
      ),
      BottomCenterQueue(
        style: const FlatQueueStyle(),
        longPressDragBehaviour: RelocateLongPressDragBehaviour(
          positions: {QueuePosition.topCenter},
        ),
      ),
    },
  );
  // NotificationManager.initialize(
  //   position: QueuePosition.topCenter,
  //   queueStyle: const OutlinedQueueStyle(),
  //   margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 48.0),
  //   maxStackSize: 3,
  //   dismissDuration: const Duration(seconds: 3),
  //   queueIndicatorBuilder: (final pendingNotificationsCount) {
  //     if (pendingNotificationsCount > 0) {
  //       return Container(
  //         padding: const EdgeInsetsGeometry.all(8),
  //         alignment: AlignmentGeometry.bottomLeft,
  //         color: Colors.blueAccent,
  //         width: 32,
  //         child: FittedBox(child: Text('$pendingNotificationsCount')),
  //       );
  //     }
  //     return null;
  //   },
  //   closeButtonBehaviour: QueueCloseButtonBehaviour.onHover,
  //   longPressDragBehaviour: RelocateLongPressDragBehaviour(
  //     positions: {QueuePosition.centerRight},
  //   ),
  //   queues: {
  //     BottomCenterQueue(
  //       maxStackSize: 1,
  //       margin: EdgeInsets.zero,
  //       style: const FlatQueueStyle(),
  //       closeButtonBehaviour: QueueCloseButtonBehaviour.onHover,
  //     ),
  //     CenterLeftQueue(
  //       maxStackSize: 3,
  //       margin: EdgeInsets.zero,
  //       style: const FilledQueueStyle(),
  //       closeButtonBehaviour: QueueCloseButtonBehaviour.onHover,
  //       longPressDragBehaviour: RelocateLongPressDragBehaviour(
  //         positions: {},
  //       ),
  //     ),
  //   },
  //   channels: {
  //     const NotificationChannel(
  //       name: 'scaffold',
  //       position: QueuePosition.bottomCenter,
  //       defaultDismissDuration: Duration(seconds: 5),
  //       defaultBackgroundColor: Colors.black,
  //       defaultForegroundColor: Colors.white,
  //       defaultColor: Colors.black,
  //       enabled: false,
  //     ),
  //     const NotificationChannel(
  //       name: 'success',
  //       position: QueuePosition.topCenter,
  //       defaultDismissDuration: Duration(seconds: 3),
  //       defaultColor: Colors.green,
  //       defaultIcon: Icon(
  //         Icons.check_circle,
  //       ),
  //     ),
  //     const NotificationChannel(
  //       name: 'scaffold.success',
  //       position: QueuePosition.bottomCenter,
  //       defaultDismissDuration: Duration(seconds: 5),
  //       defaultBackgroundColor: Colors.black,
  //       defaultForegroundColor: Colors.white,
  //       defaultColor: Colors.green,
  //       defaultIcon: Icon(
  //         Icons.check_circle,
  //       ),
  //       enabled: false,
  //     ),
  //     const NotificationChannel(
  //       name: 'error',
  //       position: QueuePosition.topCenter,
  //       defaultDismissDuration: null,
  //       defaultColor: Colors.red,
  //       defaultIcon: Icon(
  //         Icons.error,
  //       ),
  //     ),
  //     const NotificationChannel(
  //       name: 'scaffold.error',
  //       position: QueuePosition.bottomCenter,
  //       defaultDismissDuration: Duration(seconds: 5),
  //       defaultBackgroundColor: Colors.black,
  //       defaultForegroundColor: Colors.white,
  //       defaultColor: Colors.red,
  //       defaultIcon: Icon(
  //         Icons.error,
  //       ),
  //       enabled: false,
  //     ),
  //     const NotificationChannel(
  //       name: 'info',
  //       position: QueuePosition.topCenter,
  //       defaultDismissDuration: Duration(seconds: 3),
  //       defaultColor: Colors.blue,
  //       defaultIcon: Icon(
  //         Icons.info,
  //       ),
  //     ),
  //     const NotificationChannel(
  //       name: 'scaffold.info',
  //       position: QueuePosition.bottomCenter,
  //       defaultDismissDuration: Duration(seconds: 5),
  //       defaultBackgroundColor: Colors.black,
  //       defaultForegroundColor: Colors.white,
  //       defaultColor: Colors.blue,
  //       defaultIcon: Icon(
  //         Icons.info,
  //       ),
  //       enabled: false,
  //     ),
  //     const NotificationChannel(
  //       name: 'warning',
  //       position: QueuePosition.topCenter,
  //       defaultDismissDuration: Duration(seconds: 5),
  //       defaultColor: Colors.orange,
  //       defaultIcon: Icon(
  //         Icons.warning,
  //       ),
  //     ),
  //     const NotificationChannel(
  //       name: 'scaffold.warning',
  //       position: QueuePosition.bottomCenter,
  //       defaultDismissDuration: Duration(seconds: 5),
  //       defaultBackgroundColor: Colors.black,
  //       defaultForegroundColor: Colors.white,
  //       defaultColor: Colors.orange,
  //       defaultIcon: Icon(
  //         Icons.warning,
  //       ),
  //       enabled: false,
  //     ),
  //   },
  // );
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
        child: MaterialApp(
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
