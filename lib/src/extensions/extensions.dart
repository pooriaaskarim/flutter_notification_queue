// part of 'notification_manager.dart';
//
// extension ContextExtentions on BuildContext {
//   void showQuetification(final Quetification notification) =>
//       NotificationManager.instance.show(notification, this);
//
//   void showSuccess(
//     final String message, {
//     final Key? key,
//     final String? title,
//     final Duration? dismissDuration,
//     final QuetificationAction? action,
//     final bool permanent = false,
//     final bool? showCloseIcon,
//   }) =>
//       NotificationManager.instance.show(
//         Quetification.success(
//           message: message,
//           title: title,
//           dismissDuration: dismissDuration,
//           action: action,
//           permanent: permanent,
//           key: key,
//           showCloseIcon: showCloseIcon,
//         ),
//         this,
//       );
//
//   void showError(
//     final String message, {
//     final Key? key,
//     final String? title,
//     final Duration? dismissDuration,
//     final QuetificationAction? action,
//     final bool permanent = false,
//     final bool? showCloseIcon,
//   }) =>
//       NotificationManager.instance.show(
//         Quetification.error(
//           message: message,
//           title: title,
//           dismissDuration: dismissDuration,
//           action: action,
//           permanent: permanent,
//           key: key,
//           showCloseIcon: showCloseIcon,
//         ),
//         this,
//       );
//
//   void showWarning(
//     final String message, {
//     final Key? key,
//     final String? title,
//     final Duration? dismissDuration,
//     final QuetificationAction? action,
//     final bool permanent = false,
//     final bool? showCloseIcon,
//   }) =>
//       NotificationManager.instance.show(
//         Quetification.warning(
//           message: message,
//           title: title,
//           dismissDuration: dismissDuration,
//           action: action,
//           permanent: permanent,
//           key: key,
//           showCloseIcon: showCloseIcon,
//         ),
//         this,
//       );
//
//   void showInfo(
//     final String message, {
//     final Key? key,
//     final String? title,
//     final Duration? dismissDuration,
//     final QuetificationAction? action,
//     final bool permanent = false,
//     final bool? showCloseIcon,
//   }) =>
//       NotificationManager.instance.show(
//         Quetification.info(
//           message: message,
//           title: title,
//           dismissDuration: dismissDuration,
//           action: action,
//           permanent: permanent,
//           key: key,
//           showCloseIcon: showCloseIcon,
//         ),
//         this,
//       );
// }
