import 'package:flutter/material.dart';
import 'package:in_app_notifications/in_app_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp(
        title: 'InAppNotification Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const DemoPage(),
      );
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('InAppNotification Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => InAppNotificationManager.instance.show(
                  InAppNotification.success(
                    key: Key('Success notification ${DateTime.now()}'),
                    message: 'Operation successful!',
                    title: 'Success',
                  ),
                  context,
                ),
                child: const Text('Show Success'),
              ),
              ElevatedButton(
                onPressed: () => InAppNotificationManager.instance.show(
                  InAppNotification.error(
                    key: Key('Error notification ${DateTime.now()}'),
                    message: 'Something went wrong.',
                    title: 'Error',
                    action: InAppNotificationAction.button(
                      label: 'Retry',
                      onPressed: () => debugPrint('Retried!'),
                    ),
                  ),
                  context,
                ),
                child: const Text('Show Error with Button Action'),
              ),
              ElevatedButton(
                onPressed: () => InAppNotificationManager.instance.show(
                  InAppNotification.warning(
                    key: Key('Warning notification ${DateTime.now()}'),
                    message: 'Be careful!',
                    action: InAppNotificationAction.onTap(
                      onPressed: () => debugPrint('Tapped warning!'),
                    ),
                  ),
                  context,
                ),
                child: const Text('Show Warning with OnTap Action'),
              ),
              ElevatedButton(
                onPressed: () => InAppNotificationManager.instance.show(
                  InAppNotification.info(
                    key: Key(
                      'Informative Permanent Notification ${DateTime.now()}',
                    ),
                    title: 'Informative Permanent Title',
                    message: 'Informational Permanent message.'
                        '\n Here is some more text.'
                        '\n And even more text.',
                    dismissDuration: null, // Permanent until action is called
                    action: InAppNotificationAction.button(
                      label: 'Close',
                      onPressed: () {},
                    ),
                  ),
                  context,
                ),
                child: const Text('Show Permanent Info with Action'),
              ),
              ElevatedButton(
                onPressed: () async {
                  InAppNotificationManager.instance.show(
                    InAppNotification(
                      key: Key('Custom notification ${DateTime.now()}'),
                      message: 'Custom notification',
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      dismissDuration: const Duration(seconds: 1),
                      icon: const Icon(Icons.star, color: Colors.white),
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(10),
                      showCloseIcon: true,
                    ),
                    context,
                  );
                },
                child: const Text('Show Customized Notification'),
              ),
              ElevatedButton(
                onPressed: () async {
                  InAppNotificationManager.instance.show(
                    InAppNotification(
                      key:
                          Key('fallback themed notification ${DateTime.now()}'),
                      message: 'Fallback Themed Notification',
                      borderRadius: BorderRadius.circular(10),
                      showCloseIcon: true,
                    ),
                    context,
                  );
                },
                child: const Text('Show Fallback Themed Notification'),
              ),
            ],
          ),
        ),
      );
}
