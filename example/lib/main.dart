import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import 'studio/bloc/notification_bloc.dart';
import 'studio/bloc/setup_bloc.dart';
import 'studio/bloc/studio_bloc.dart';
import 'studio/studio_home.dart';
import 'studio/studio_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration is managed reactively by SetupBloc —
  // no manual FlutterNotificationQueue.configure() call needed.

  runApp(const NFQStudioApp());
}

class NFQStudioApp extends StatelessWidget {
  const NFQStudioApp({super.key});

  @override
  Widget build(final BuildContext context) {
    final setupBloc = SetupBloc();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (final _) => setupBloc),
        BlocProvider(
          create: (final _) => NotificationBloc(setupBloc: setupBloc),
        ),
        BlocProvider(create: (final _) => StudioBloc()),
      ],
      child: BlocBuilder<StudioBloc, StudioState>(
        builder: (final context, final state) => MaterialApp(
          title: 'NFQ Studio',
          debugShowCheckedModeBanner: false,
          theme: StudioTheme.light(),
          darkTheme: StudioTheme.dark(),
          themeMode: state.themeMode,
          builder: (final context, final child) {
            StudioTheme.update(context);
            return FlutterNotificationQueue.builder(context, child);
          },
          home: const StudioHome(),
        ),
      ),
    );
  }
}
