import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:in_app_notifications/in_app_notifications.dart';

void main() {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  FlutterNativeSplash.remove();
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
        appBar: AppBar(
          title: const Text('InAppNotification Comprehensive Demo'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildAdaptiveGrid(),
        ),
      );

  Widget _buildAdaptiveGrid() => LayoutBuilder(
        builder: (final context, final constraints) {
          final screenWidth = constraints.maxWidth;
          const tabletBreakPoint = 900;
          const phoneBreakPoint = 600;
          final columnCount = screenWidth < phoneBreakPoint
              ? 1
              : screenWidth < tabletBreakPoint
                  ? 2
                  : 3;
          final padding = EdgeInsets.symmetric(
            horizontal: (screenWidth < phoneBreakPoint)
                ? 0
                : (screenWidth < tabletBreakPoint)
                    ? screenWidth / 8
                    : screenWidth / 5,
          );

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            padding: padding,
            itemCount: _notificationExamples.length,
            itemBuilder: (final context, final index) {
              final example = _notificationExamples[index];
              return _buildNotificationButton(context, example);
            },
          );
        },
      );

  Widget _buildNotificationButton(
    final BuildContext context,
    final NotificationExample example,
  ) =>
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => example.onPressed(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  example.color.withValues(alpha: 0.1),
                  example.color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  example.icon,
                  size: 24,
                  color: example.color,
                ),
                const SizedBox(height: 8),
                Text(
                  example.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: example.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );

  List<NotificationExample> get _notificationExamples => [
        // Basic types
        NotificationExample(
          title: 'Success Message',
          icon: Icons.check_circle,
          color: Colors.green,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.success(
              key: Key('Success notification ${DateTime.now()}'),
              message: 'Operation completed successfully!',
              title: 'Success',
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Error with Retry',
          icon: Icons.error,
          color: Colors.red,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.error(
              key: Key('Error notification ${DateTime.now()}'),
              message: 'Network connection failed. Please try again.',
              title: 'Connection Error',
              action: InAppNotificationAction.button(
                label: 'Retry',
                onPressed: () => debugPrint('Retrying connection...'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Warning with Tap',
          icon: Icons.warning,
          color: Colors.orange,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.warning(
              key: Key('Warning notification ${DateTime.now()}'),
              message: 'Low storage space detected.',
              title: 'Storage Warning',
              action: InAppNotificationAction.onTap(
                onPressed: () => debugPrint('Opening storage settings...'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Permanent Info',
          icon: Icons.info,
          color: Colors.blue,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.info(
              key: Key('Info permanent ${DateTime.now()}'),
              title: 'New Feature Available',
              message: 'Check out our new dark mode feature!',
              dismissDuration: null,
              action: InAppNotificationAction.button(
                label: 'Explore',
                onPressed: () => debugPrint('Opening new features...'),
              ),
            ),
            context,
          ),
        ),

        // RTL Languages
        NotificationExample(
          title: 'اطلاعیه موفقیت',
          icon: Icons.language,
          color: Colors.purple,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.success(
              key: Key('Persian notification ${DateTime.now()}'),
              title: 'اطلاعیه موفقیت',
              message: 'عملیات با موفقیت انجام شد! سیستم آماده استفاده است.',
              action: InAppNotificationAction.button(
                label: 'تأیید',
                onPressed: () => debugPrint('Persian action pressed'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'إشعار تحديث التطبيق',
          icon: Icons.language,
          color: Colors.teal,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.info(
              key: Key('Arabic notification ${DateTime.now()}'),
              title: 'إشعار هام',
              message:
                  'تم تحديث التطبيق بنجاح. يرجى إعادة تشغيل التطبيق للحصول على أفضل تجربة.',
              action: InAppNotificationAction.button(
                label: 'إعادة التشغيل',
                onPressed: () => debugPrint('Arabic restart action'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'אזהרת אחסון',
          icon: Icons.language,
          color: Colors.indigo,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.warning(
              key: Key('Hebrew notification ${DateTime.now()}'),
              title: 'אזהרת מערכת',
              message: 'שטח האחסון עומד להתמלא. אנא פנה מקום נוסף.',
              action: InAppNotificationAction.onTap(
                onPressed: () => debugPrint('Hebrew storage action'),
              ),
            ),
            context,
          ),
        ),

        // Other Languages
        NotificationExample(
          title: 'Operación Exitosa',
          icon: Icons.language,
          color: Colors.deepOrange,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.success(
              key: Key('Spanish notification ${DateTime.now()}'),
              title: '¡Éxito!',
              message:
                  '¡La operación se completó exitosamente! Tu archivo ha sido guardado.',
              action: InAppNotificationAction.button(
                label: 'Aceptar',
                onPressed: () => debugPrint('Spanish accept action'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'アップデート通知',
          icon: Icons.language,
          color: Colors.pink,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.info(
              key: Key('Japanese notification ${DateTime.now()}'),
              title: '新しいメッセージ',
              message: 'アップデートが利用可能です。最新の機能を体験するために今すぐアップデートしてください。',
              action: InAppNotificationAction.button(
                label: '更新する',
                onPressed: () => debugPrint('Japanese update action'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Avertissement Session',
          icon: Icons.language,
          color: Colors.blue[800]!,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.warning(
              key: Key('French notification ${DateTime.now()}'),
              title: 'Attention',
              message:
                  'Votre session expirera dans 5 minutes. Veuillez sauvegarder votre travail.',
              action: InAppNotificationAction.button(
                label: 'Prolonger',
                onPressed: () => debugPrint('French extend session'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Verbindungsfehler',
          icon: Icons.language,
          color: Colors.brown,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.error(
              key: Key('German notification ${DateTime.now()}'),
              title: 'Fehler',
              message:
                  'Die Verbindung zum Server konnte nicht hergestellt werden.',
              action: InAppNotificationAction.button(
                label: 'Wiederholen',
                onPressed: () => debugPrint('German retry action'),
              ),
            ),
            context,
          ),
        ),

        // Long Text Examples
        NotificationExample(
          title: 'Terms Update (Long)',
          icon: Icons.article,
          color: Colors.cyan,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.info(
              key: Key('Long message ${DateTime.now()}'),
              title: 'Terms of Service Update',
              message:
                  'We have updated our Terms of Service and Privacy Policy. '
                  'The changes include new data processing guidelines, enhanced security measures, '
                  'improved user rights, and updated third-party integrations. '
                  'Please review the changes carefully as they will take effect in 30 days. '
                  'Your continued use of our service constitutes acceptance of these terms.',
              dismissDuration: const Duration(seconds: 8),
              action: InAppNotificationAction.button(
                label: 'Review Terms',
                onPressed: () => debugPrint('Opening terms review'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'بروزرسانی سیستم',
          icon: Icons.article,
          color: Colors.deepPurple,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.warning(
              key: Key('Long Persian ${DateTime.now()}'),
              title: 'اطلاعیه مهم سیستم',
              message: 'سیستم در حال انجام بروزرسانی اساسی است. '
                  'این فرآیند ممکن است چند دقیقه طول بکشد و در طول این مدت '
                  'برخی از قابلیت‌ها موقتاً در دسترس نخواهند بود. '
                  'لطفاً کارهای خود را ذخیره کرده و تا اتمام فرآیند صبر کنید. '
                  'پس از اتمام بروزرسانی، سیستم با عملکرد بهتر و امکانات جدید '
                  'در اختیار شما خواهد بود.',
              dismissDuration: const Duration(seconds: 10),
              action: InAppNotificationAction.button(
                label: 'متوجه شدم',
                onPressed: () => debugPrint('Persian acknowledgment'),
              ),
            ),
            context,
          ),
        ),

        // Creative Custom Examples
        NotificationExample(
          title: 'Custom Purple Style',
          icon: Icons.gradient,
          color: Colors.purple,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification(
              key: Key('Gradient purple ${DateTime.now()}'),
              title: '🎨 Creative Notification',
              message:
                  'This is a custom styled notification with beautiful colors!',
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(8),
              icon: const Icon(Icons.palette, color: Colors.white),
              showCloseIcon: true,
              dismissDuration: const Duration(seconds: 5),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Gaming Achievement',
          icon: Icons.stars,
          color: Colors.amber,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification(
              key: Key('Achievement ${DateTime.now()}'),
              title: '🏆 Achievement Unlocked!',
              message:
                  'Congratulations! You have completed 100 notifications demo!',
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.black,
              borderRadius: BorderRadius.circular(15),
              icon: const Icon(Icons.emoji_events, color: Colors.black),
              action: InAppNotificationAction.button(
                label: 'Collect Reward',
                onPressed: () => debugPrint('Collecting achievement reward'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Social Like Alert',
          icon: Icons.favorite,
          color: Colors.pink,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification(
              key: Key('Social ${DateTime.now()}'),
              title: '💖 Sarah liked your photo',
              message: 'Your sunset photo from yesterday received a new like!',
              backgroundColor: Colors.pink[50],
              foregroundColor: Colors.pink[800],
              borderRadius: BorderRadius.circular(25),
              icon: Icon(Icons.favorite, color: Colors.pink[600]),
              action: InAppNotificationAction.onTap(
                onPressed: () => debugPrint('Opening photo'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Dark Mode Toggle',
          icon: Icons.dark_mode,
          color: Colors.grey[800]!,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification(
              key: Key('Dark theme ${DateTime.now()}'),
              title: '🌙 Dark Mode Activated',
              message: 'Your eyes will thank you! Dark mode is now enabled.',
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.dark_mode, color: Colors.white),
              showCloseIcon: true,
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Now Playing Music',
          icon: Icons.music_note,
          color: Colors.green,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification(
              key: Key('Music ${DateTime.now()}'),
              title: '🎵 Now Playing',
              message:
                  '"Bohemian Rhapsody" by Queen is now playing in the background.',
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(30),
              icon: const Icon(Icons.music_note, color: Colors.white),
              dismissDuration: const Duration(seconds: 4),
              action: InAppNotificationAction.button(
                label: 'Open Player',
                onPressed: () => debugPrint('Opening music player'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Flash Sale Alert',
          icon: Icons.shopping_cart,
          color: Colors.red,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification(
              key: Key('Sale ${DateTime.now()}'),
              title: '🛍️ Flash Sale Alert!',
              message:
                  '50% OFF on all electronics! Limited time offer ending in 2 hours.',
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              icon:
                  const Icon(Icons.local_fire_department, color: Colors.white),
              dismissDuration: const Duration(seconds: 6),
              action: InAppNotificationAction.button(
                label: 'Shop Now',
                onPressed: () => debugPrint('Opening shop'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Weather Forecast',
          icon: Icons.wb_sunny,
          color: Colors.orange,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification(
              key: Key('Weather ${DateTime.now()}'),
              title: '🌤️ Weather Update',
              message:
                  'Sunny weather expected today with a high of 75°F. Perfect for outdoor activities!',
              backgroundColor: Colors.orange[400],
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              icon: const Icon(Icons.wb_sunny, color: Colors.white),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'Celebration Notice',
          icon: Icons.emoji_emotions,
          color: Colors.yellow[700]!,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification(
              key: Key('Emoji rich ${DateTime.now()}'),
              title: '🎉🎊 Celebration Time! 🎊🎉',
              message:
                  '🚀 Your app has reached 1000 downloads! 🎯✨ Amazing work! 👏💪 Keep it up! 🔥⭐',
              backgroundColor: Colors.yellow[600],
              foregroundColor: Colors.black,
              borderRadius: BorderRadius.circular(20),
              icon: const Icon(Icons.celebration, color: Colors.black),
              action: InAppNotificationAction.button(
                label: '🎉 Celebrate',
                onPressed: () => debugPrint('Celebration time!'),
              ),
            ),
            context,
          ),
        ),

        // System-like notifications
        NotificationExample(
          title: 'Low Battery Warning',
          icon: Icons.battery_alert,
          color: Colors.red[700]!,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.warning(
              key: Key('Battery ${DateTime.now()}'),
              title: '🔋 Battery Low',
              message:
                  'Device battery is at 15%. Consider connecting to power.',
              action: InAppNotificationAction.button(
                label: 'Power Settings',
                onPressed: () => debugPrint('Opening power settings'),
              ),
            ),
            context,
          ),
        ),
        NotificationExample(
          title: 'App Update Ready',
          icon: Icons.system_update,
          color: Colors.blue[600]!,
          onPressed: (final context) => InAppNotificationManager.instance.show(
            InAppNotification.info(
              key: Key('Update ${DateTime.now()}'),
              title: '📱 App Update Available',
              message:
                  'Version 2.1.0 is available with bug fixes and new features.',
              dismissDuration: null,
              action: InAppNotificationAction.button(
                label: 'Update Now',
                onPressed: () => debugPrint('Starting app update'),
              ),
            ),
            context,
          ),
        ),
      ];
}

class NotificationExample {
  const NotificationExample({
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final Color color;
  final void Function(BuildContext context) onPressed;
}
