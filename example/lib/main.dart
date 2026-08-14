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

  // NotificationController is managed reactively by SetupBloc —
  // NotificationScope is mounted in MaterialApp.builder below.

  runApp(const NFQStudioApp());
}

class NFQStudioApp extends StatelessWidget {
  const NFQStudioApp({super.key});

  @override
  Widget build(final BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (final _) => SetupBloc()),
          BlocProvider(
            create: (final context) => NotificationBloc(
              setupBloc: context.read<SetupBloc>(),
            ),
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
              return BlocBuilder<SetupBloc, SetupState>(
                builder: (final context, final _) => NotificationScope(
                  controller: context.read<SetupBloc>().controller,
                  child: child!,
                ),
              );
            },
            home: const StudioHome(),
          ),
        ),
      );
}
