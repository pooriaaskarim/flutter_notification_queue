import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import 'studio/bloc/studio_bloc.dart';
import 'studio/bloc/studio_state.dart';
import 'studio/studio_home.dart';
import 'studio/studio_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNotificationQueue.configure(
    queues: {NotificationQueue.defaultQueue()},
    channels: NotificationChannel.standardChannels(),
  );

  runApp(const NFQStudioApp());
}

class NFQStudioApp extends StatelessWidget {
  const NFQStudioApp({super.key});

  @override
  Widget build(final BuildContext context) => BlocProvider(
        create: (final _) => StudioBloc(),
        child: BlocBuilder<StudioBloc, StudioState>(
          builder: (final context, final state) => MaterialApp(
            title: 'NFQ Studio',
            debugShowCheckedModeBanner: false,
            theme: StudioTheme.light(),
            darkTheme: StudioTheme.dark(),
            themeMode: state.themeMode,
            builder: FlutterNotificationQueue.builder,
            home: const StudioHome(),
          ),
        ),
      );
}
