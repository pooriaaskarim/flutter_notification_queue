import 'package:flutter/material.dart';

class Utils {
  Utils._();

  static TextDirection estimateDirectionOfText(final String text) {
    bool startsWithRtl(final String text) {
      const String ltrChars =
          r'A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0300-\u0590'
          r'\u0800-\u1FFF\u2C00-\uFB1C\uFDFE-\uFE6F\uFEFD-\uFFFF';
      const String rtlChars = r'\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC';
      return RegExp('^[^$ltrChars]*[$rtlChars]').hasMatch(text);
    }

    final words = text.split(RegExp(r'\s+'));
    if (startsWithRtl(words.first)) {
      return TextDirection.rtl;
    } else {
      return TextDirection.ltr;
    }
  }

  static const String phone = 'phone';
  static const String tablet = 'tablet';
  static const String desktop = 'desktop';

  static const Breakpoint phoneBreakPoint = Breakpoint(
    start: 0,
    end: 600,
    name: phone,
  );
  static const Breakpoint tabletBreakPoint = Breakpoint(
    start: 601,
    end: 900,
    name: tablet,
  );
  static const Breakpoint desktopBreakPoint = Breakpoint(
    start: 901,
    end: 1920,
    name: desktop,
  );

  static EdgeInsets horizontalPadding(
    final BuildContext context, {
    final bool largerPaddings = false,
  }) {
    final width = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(
      horizontal: (width < phoneBreakPoint.end)
          ? 0
          : (width >= phoneBreakPoint.end && width < tabletBreakPoint.start)
              ? width / 123
              : (width >= tabletBreakPoint.end &&
                      width < desktopBreakPoint.start)
                  ? width / (largerPaddings ? 5 : 8)
                  : width / (largerPaddings ? 5 : 8),
    );
  }

  static EdgeInsets verticalPadding(final BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return EdgeInsets.symmetric(vertical: (height < 1200) ? 0 : height / 10);
  }
}

@immutable
class Breakpoint {
  const Breakpoint({
    required this.start,
    required this.end,
    this.name,
    this.data,
  });
  final double start;
  final double end;
  final String? name;
  final dynamic data;

  Breakpoint copyWith({
    final double? start,
    final double? end,
    final String? name,
    final dynamic data,
  }) =>
      Breakpoint(
        start: start ?? this.start,
        end: end ?? this.end,
        name: name ?? this.name,
        data: data ?? this.data,
      );

  @override
  String toString() => 'Breakpoint(start: $start, end: $end, name: $name)';

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is Breakpoint &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          name == other.name;

  @override
  int get hashCode => start.hashCode * end.hashCode * name.hashCode;
}
