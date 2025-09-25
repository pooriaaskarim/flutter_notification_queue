import 'package:flutter/material.dart';

import '../../utils/utils.dart';

// class NotificationCoreWidget extends StatelessWidget {
//   const NotificationCoreWidget({super.key});
//
//
//   @override
//   Widget build(BuildContext context) {
//
//     return AutomaticKeepAlive(
//
//       child: ConstrainedBox(
//         constraints: Utils.horizontalConstraints(context),
//         child: ValueListenableBuilder(
//           valueListenable: _isExpanded,
//           builder: (final context, final isExpanded, final child) => Material(
//             borderRadius: _borderRadius,
//             elevation: _elevation,
//             shadowColor: _themeData.shadowColor,
//             type: MaterialType.canvas,
//             color: _resolvedBackground.withValues(alpha: _opacity),
//             child: InkWell(
//               borderRadius: _borderRadius,
//               onHover:
//               widget.queue.style.showCloseButton == QueueCloseButton.onHover
//                   ? (final isHovering) {
//                 _showCloseButton.value = isHovering;
//               }
//                   : null,
//               onTap: () {
//                 if (_hasOnTapAction) {
//                   widget.action!.onPressed();
//                   dismiss();
//                 }
//               },
//               child: Stack(
//                 children: [
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 220),
//                     curve: Curves.easeOut,
//                     padding: EdgeInsets.symmetric(
//                       vertical: isExpanded ? 16 : 8,
//                       horizontal: 36,
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         _getTitle(isExpanded: isExpanded),
//                         _getContent(isExpanded: isExpanded),
//                         _getActionButton(),
//                       ],
//                     ),
//                   ),
//                   _timerIndicator(isExpanded: isExpanded),
//                   _getExpandButton(isExpanded: isExpanded),
//                   _getCloseButton(),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//
// }
