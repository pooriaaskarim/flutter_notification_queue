import 'package:flutter/material.dart';
import 'package:in_app_notifications/in_app_notifications.dart';
import 'package:in_app_notifications/src/utils/utils.dart' as ut;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InAppNotification Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    ut.Utils.desktop;
    return Scaffold(
      appBar: AppBar(title: const Text('InAppNotification Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => InAppNotification.success(
                message: 'Operation successful!',
                title: 'Success',
              ).show(context),
              child: const Text('Show Success'),
            ),
            ElevatedButton(
              onPressed: () => InAppNotification.error(
                message: 'Something went wrong.',
                title: 'Error',
                action: InAppNotificationAction.button(
                  label: 'Retry',
                  onPressed: () => print('Retried!'),
                ),
              ).show(context),
              child: const Text('Show Error with Button Action'),
            ),
            ElevatedButton(
              onPressed: () => InAppNotification.warning(
                message: 'Be careful!',
                action: InAppNotificationAction.onTap(
                  onPressed: () => print('Tapped warning!'),
                ),
              ).show(context),
              child: const Text('Show Warning with OnTap Action'),
            ),
            ElevatedButton(
              onPressed: () => InAppNotification.info(
                title: 'Informative Title',
                message: 'Informational message.',
                dismissDuration:
                    Duration(milliseconds: 499), // Permanent until action
                action: InAppNotificationAction.button(
                  label: 'Close',
                  onPressed: () {},
                ),
              ).show(context),
              child: const Text('Show Permanent Info with Action'),
            ),
            ElevatedButton(
              onPressed: () async {
                var inAppNotification = InAppNotification(
                  message: 'Custom notification',
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  dismissDuration: Duration(seconds: 1),
                  icon: const Icon(Icons.star, color: Colors.white),
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(10),
                  showCloseIcon: true,
                );
                inAppNotification.show(context);
                // inAppNotification.dispose();
                await Future.delayed(
                  const Duration(seconds: 2),
                );
                inAppNotification.show(context);
              },
              child: const Text('Show Custom'),
            ),
          ],
        ),
      ),
    );
  }
}
