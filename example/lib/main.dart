// import 'package:flutter/material.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:flutter_notification_queue/flutter_notification_queue.dart';
//
// void main() {
//   final WidgetsBinding widgetsBinding =
//       WidgetsFlutterBinding.ensureInitialized();
//
//   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
//
//   FlutterNativeSplash.remove();
//
//   // Configure the notification manager
//   NotificationManager.instance
//     ..config = const QuetificationConfig(
//       alignment: AlignmentDirectional.bottomCenter,
//       defaultDismissDuration: Duration(seconds: 5),
//     )
//     ..configureQueues(configurations: {
//       TopCenterQueueConfiguration(),
//       BottomCenterQueueConfiguration()
//     });
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(final BuildContext context) => MaterialApp(
//         title: 'NotificationQueue Demo',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           useMaterial3: true,
//         ),
//         home: const DemoPage(),
//       );
// }
//
// class DemoPage extends StatelessWidget {
//   const DemoPage({super.key});
//
//   @override
//   Widget build(final BuildContext context) {
//     final themeData = Theme.of(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('NotificationQueue Demo'),
//         backgroundColor: themeData.colorScheme.primaryContainer,
//         foregroundColor: themeData.colorScheme.onPrimaryContainer,
//         elevation: 2,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: _buildAdaptiveGrid(),
//       ),
//     );
//   }
//
//   Widget _buildAdaptiveGrid() => LayoutBuilder(
//         builder: (final context, final constraints) {
//           final screenWidth = constraints.maxWidth;
//           const tabletBreakPoint = 900;
//           const phoneBreakPoint = 600;
//
//           final columnCount = screenWidth < phoneBreakPoint
//               ? 1
//               : screenWidth < tabletBreakPoint
//                   ? 2
//                   : 3;
//
//           final padding = EdgeInsets.symmetric(
//             horizontal: screenWidth < phoneBreakPoint
//                 ? 0
//                 : screenWidth < tabletBreakPoint
//                     ? screenWidth / 8
//                     : screenWidth / 5,
//           );
//
//           return GridView.builder(
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: columnCount,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//               childAspectRatio: screenWidth < phoneBreakPoint ? 3.5 : 2.5,
//             ),
//             padding: padding,
//             itemCount: _notificationExamples.length,
//             itemBuilder: (final context, final index) {
//               final example = _notificationExamples[index];
//               return example.buildNotificationButton(context, example);
//             },
//           );
//         },
//       );
//
//   List<NotificationExample> get _notificationExamples => [
//         // Basic notification
//         NotificationExample(
//           title: 'Basic Notification',
//           icon: Icons.info_outline,
//           color: Colors.blueGrey,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification(
//               key: Key(
//                 'Basic notification ${DateTime.now().millisecondsSinceEpoch}',
//               ),
//               message: 'This is a basic notification with custom styling.',
//             ),
//             context,
//           ),
//         ),
//
//         // Predefined types
//         NotificationExample(
//           title: 'Success Message',
//           icon: Icons.check_circle,
//           color: Colors.green,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.success(
//               key: Key('Success ${DateTime.now().millisecondsSinceEpoch}'),
//               message: 'Operation completed successfully!',
//               title: 'Success',
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Error with Retry',
//           icon: Icons.error,
//           color: Colors.red,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.error(
//               key: Key('Error ${DateTime.now().millisecondsSinceEpoch}'),
//               message: 'Network connection failed. Please try again.',
//               title: 'Connection Error',
//               action: QuetificationAction.button(
//                 label: 'Retry',
//                 onPressed: () => debugPrint('Retrying connection...'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Warning with Tap',
//           icon: Icons.warning,
//           color: Colors.orange,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.warning(
//               key: Key('Warning ${DateTime.now().millisecondsSinceEpoch}'),
//               message: 'Low storage space detected. Tap to manage.',
//               title: 'Storage Warning',
//               action: QuetificationAction.onTap(
//                 onPressed: () => debugPrint('Opening storage settings...'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Permanent Info',
//           icon: Icons.info,
//           color: Colors.blue,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.info(
//               key: Key(
//                 'Info permanent ${DateTime.now().millisecondsSinceEpoch}',
//               ),
//               title: 'New Feature Available',
//               message: 'Check out our new dark mode feature!'
//                   ' This notification stays until you interact with it.',
//               showCloseIcon: true,
//               action: QuetificationAction.button(
//                 label: 'Explore',
//                 onPressed: () => debugPrint('Opening new features...'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         // RTL Languages
//         NotificationExample(
//           title: 'اطلاعیه فارسی',
//           icon: Icons.language,
//           color: Colors.purple,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.success(
//               key: Key('Persian ${DateTime.now().millisecondsSinceEpoch}'),
//               title: 'اطلاعیه موفقیت',
//               message: 'عملیات با موفقیت انجام شد! سیستم آماده استفاده است.',
//               action: QuetificationAction.button(
//                 label: 'تأیید',
//                 onPressed: () => debugPrint('Persian action pressed'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'إشعار عربي',
//           icon: Icons.language,
//           color: Colors.teal,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.info(
//               key: Key('Arabic ${DateTime.now().millisecondsSinceEpoch}'),
//               title: 'إشعار هام',
//               message: 'تم تحديث التطبيق بنجاح. يرجى إعادة تشغيل التطبيق'
//                   ' للحصول على أفضل تجربة.',
//               action: QuetificationAction.button(
//                 label: 'إعادة التشغيل',
//                 onPressed: () => debugPrint('Arabic restart action'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'התראה בעברית',
//           icon: Icons.language,
//           color: Colors.indigo,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.warning(
//               key: Key('Hebrew ${DateTime.now().millisecondsSinceEpoch}'),
//               title: 'אזהרת מערכת',
//               message: 'שטח האחסון עומד להתמלא. אנא פנה מקום נוסף.',
//               action: QuetificationAction.onTap(
//                 onPressed: () => debugPrint('Hebrew storage action'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         // Other Languages
//         NotificationExample(
//           title: 'Notificación Española',
//           icon: Icons.language,
//           color: Colors.deepOrange,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.success(
//               key: Key('Spanish ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '¡Éxito!',
//               message: '¡La operación se completó exitosamente!'
//                   ' Tu archivo ha sido guardado.',
//               action: QuetificationAction.button(
//                 label: 'Aceptar',
//                 onPressed: () => debugPrint('Spanish accept action'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: '日本語通知',
//           icon: Icons.language,
//           color: Colors.pink,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.info(
//               key: Key('Japanese ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '新しいメッセージ',
//               message: 'アップデートが利用可能です。最新の機能を体験するために今すぐアップデートしてください。',
//               action: QuetificationAction.button(
//                 label: '更新する',
//                 onPressed: () => debugPrint('Japanese update action'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Notification Française',
//           icon: Icons.language,
//           color: Colors.blue[800]!,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.warning(
//               key: Key('French ${DateTime.now().millisecondsSinceEpoch}'),
//               title: 'Attention',
//               message: 'Votre session expirera dans 5 minutes.'
//                   ' Veuillez sauvegarder votre travail.',
//               action: QuetificationAction.button(
//                 label: 'Prolonger',
//                 onPressed: () => debugPrint('French extend session'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Deutsche Benachrichtigung',
//           icon: Icons.language,
//           color: Colors.brown,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.error(
//               key: Key('German ${DateTime.now().millisecondsSinceEpoch}'),
//               title: 'Fehler',
//               message:
//                   'Die Verbindung zum Server konnte nicht hergestellt werden.',
//               action: QuetificationAction.button(
//                 label: 'Wiederholen',
//                 onPressed: () => debugPrint('German retry action'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         // Long Text Examples
//         NotificationExample(
//           title: 'Long Text Example',
//           icon: Icons.article,
//           color: Colors.cyan,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.info(
//               key: Key('Long message ${DateTime.now().millisecondsSinceEpoch}'),
//               title: 'Terms of Service Update',
//               message:
//                   'We have updated our Terms of Service and Privacy Policy. '
//                   'The changes include new data processing guidelines,'
//                   ' enhanced security measures, improved user rights,'
//                   ' and updated third-party integrations. Please review'
//                   ' the changes carefully as they will take'
//                   ' effect in 30 days. Your continued use of our'
//                   ' service constitutes acceptance of these terms.',
//               dismissDuration: const Duration(seconds: 8),
//               action: QuetificationAction.button(
//                 label: 'Review Terms',
//                 onPressed: () => debugPrint('Opening terms review'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'متن طولانی فارسی',
//           icon: Icons.article,
//           color: Colors.deepPurple,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.warning(
//               key: Key('Long Persian ${DateTime.now().millisecondsSinceEpoch}'),
//               title: 'اطلاعیه مهم سیستم',
//               message: 'سیستم در حال انجام بروزرسانی اساسی است. '
//                   'این فرآیند ممکن است چند دقیقه طول بکشد و در طول این مدت '
//                   'برخی از قابلیت‌ها موقتاً در دسترس نخواهند بود. '
//                   'لطفاً کارهای خود را ذخیره کرده و تا اتمام فرآیند صبر کنید. '
//                   'پس از اتمام بروزرسانی، سیستم با عملکرد بهتر و امکانات جدید '
//                   'در اختیار شما خواهد بود.',
//               dismissDuration: const Duration(seconds: 10),
//               action: QuetificationAction.button(
//                 label: 'متوجه شدم',
//                 onPressed: () => debugPrint('Persian acknowledgment'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         // Creative Custom Examples
//         NotificationExample(
//           title: 'Custom Purple Style',
//           icon: Icons.palette,
//           color: Colors.purple,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification(
//               key:
//                   Key('Purple custom ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '🎨 Creative Notification',
//               message:
//                   'This is a custom styled notification with beautiful colors!',
//               backgroundColor: Colors.purple[700],
//               foregroundColor: Colors.white,
//               icon: Icons.palette,
//               showCloseIcon: true,
//               dismissDuration: const Duration(seconds: 5),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Gaming Achievement',
//           icon: Icons.emoji_events,
//           color: Colors.amber,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification(
//               key: Key('Achievement ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '🏆 Achievement Unlocked!',
//               message:
//                   'Congratulations! You have completed 100 notifications demo!',
//               backgroundColor: Colors.amber[700],
//               foregroundColor: Colors.black,
//               icon: Icons.emoji_events,
//               action: QuetificationAction.button(
//                 label: 'Collect Reward',
//                 onPressed: () => debugPrint('Collecting achievement reward'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Social Notification',
//           icon: Icons.favorite,
//           color: Colors.pink,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification(
//               key: Key('Social ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '💖 Sarah liked your photo',
//               message: 'Your sunset photo from yesterday received a new like!',
//               backgroundColor: Colors.pink[50],
//               foregroundColor: Colors.pink[800],
//               action: QuetificationAction.onTap(
//                 onPressed: () => debugPrint('Opening photo'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Dark Theme Toggle',
//           icon: Icons.dark_mode,
//           color: Colors.grey[800]!,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification(
//               key: Key('Dark theme ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '🌙 Dark Mode Activated',
//               message: 'Your eyes will thank you! Dark mode is now enabled.',
//               backgroundColor: Colors.grey[900],
//               foregroundColor: Colors.white,
//               icon: Icons.dark_mode,
//               showCloseIcon: true,
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Music Player',
//           icon: Icons.music_note,
//           color: Colors.green,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification(
//               key: Key('Music ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '🎵 Now Playing',
//               message: '"Bohemian Rhapsody" by Queen'
//                   ' is now playing in the background.',
//               backgroundColor: Colors.green[600],
//               foregroundColor: Colors.white,
//               icon: Icons.music_note,
//               dismissDuration: const Duration(seconds: 4),
//               action: QuetificationAction.button(
//                 label: 'Open Player',
//                 onPressed: () => debugPrint('Opening music player'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Flash Sale Alert',
//           icon: Icons.local_fire_department,
//           color: Colors.red,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification(
//               key: Key('Sale ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '🔥 Flash Sale Alert!',
//               message: '50% OFF on all electronics!'
//                   ' Limited time offer ending in 2 hours.',
//               backgroundColor: Colors.red[600],
//               foregroundColor: Colors.white,
//               icon: Icons.local_fire_department,
//               dismissDuration: const Duration(seconds: 6),
//               action: QuetificationAction.button(
//                 label: 'Shop Now',
//                 onPressed: () => debugPrint('Opening shop'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Weather Update',
//           icon: Icons.wb_sunny,
//           color: Colors.orange,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification(
//               key: Key('Weather ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '🌤️ Weather Update',
//               message: 'Sunny weather expected today with a high of 75°F.'
//                   ' Perfect for outdoor activities!',
//               backgroundColor: Colors.orange[400],
//               foregroundColor: Colors.white,
//               dismissDuration: const Duration(seconds: 4),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'Celebration',
//           icon: Icons.celebration,
//           color: Colors.yellow[700]!,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification(
//               key: Key('Celebration ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '🎉🎊 Celebration Time! 🎊🎉',
//               message: '🚀 Your app has reached 1000 downloads!'
//                   ' 🎯✨ Amazing work! 👏💪 Keep it up! 🔥⭐',
//               backgroundColor: Colors.yellow[600],
//               foregroundColor: Colors.black,
//               icon: Icons.celebration,
//               action: QuetificationAction.button(
//                 label: '🎉 Celebrate',
//                 onPressed: () => debugPrint('Celebration time!'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         // System-like notifications
//         NotificationExample(
//           title: 'Battery Warning',
//           icon: Icons.battery_alert,
//           color: Colors.red[700]!,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.warning(
//               key: Key('Battery ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '🔋 Battery Low',
//               message:
//                   'Device battery is at 15%. Consider connecting to power.',
//               action: QuetificationAction.button(
//                 label: 'Power Settings',
//                 onPressed: () => debugPrint('Opening power settings'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         NotificationExample(
//           title: 'App Update',
//           icon: Icons.system_update,
//           color: Colors.blue[600]!,
//           onPressed: (final context) => NotificationManager.instance.show(
//             Quetification.info(
//               key: Key('Update ${DateTime.now().millisecondsSinceEpoch}'),
//               title: '📱 App Update Available',
//               message:
//                   'Version 2.1.0 is available with bug fixes and new features.',
//               showCloseIcon: true,
//               action: QuetificationAction.button(
//                 label: 'Update Now',
//                 onPressed: () => debugPrint('Starting app update'),
//               ),
//             ),
//             context,
//           ),
//         ),
//
//         // Queue stress test
//         NotificationExample(
//           title: 'Queue Test (5x)',
//           icon: Icons.queue,
//           color: Colors.deepPurple,
//           onPressed: (final context) {
//             for (int i = 0; i < 5; i++) {
//               NotificationManager.instance.show(
//                 Quetification.info(
//                   key: Key(
//                     'Queue test $i ${DateTime.now().millisecondsSinceEpoch}',
//                   ),
//                   title: 'Queue Test #${i + 1}',
//                   message:
//                       'This is notification ${i + 1} of 5 in the queue test.',
//                   dismissDuration: Duration(seconds: 3 + i),
//                 ),
//                 context,
//               );
//             }
//           },
//         ),
//       ];
// }
//
// class NotificationExample {
//   const NotificationExample({
//     required this.title,
//     required this.icon,
//     required this.color,
//     required this.onPressed,
//   });
//
//   final String title;
//   final IconData icon;
//   final Color color;
//   final void Function(BuildContext context) onPressed;
//
//   Widget buildNotificationButton(
//     final BuildContext context,
//     final NotificationExample example,
//   ) =>
//       Card(
//         elevation: 3,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () => example.onPressed(context),
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               gradient: LinearGradient(
//                 colors: [
//                   example.color.withValues(alpha: 0.1),
//                   example.color.withValues(alpha: 0.05),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   example.icon,
//                   size: 24,
//                   color: example.color,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   example.title,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: example.color,
//                   ),
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
// }
