import 'package:flutter/material.dart';

class ColorUtils {
  ColorUtils._();
  static MaterialColor getMaterialColor(final Color color) {
    final int red = color.r.round() & 0xff;
    final int green = color.g.round() & 0xff;
    final int blue = color.b.round() & 0xff;

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.toARGB32(), shades);
  }
}

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

  static const _Breakpoint _phoneBreakPoint = _Breakpoint(
    start: 0,
    end: 600,
    name: phone,
  );
  static const _Breakpoint _tabletBreakPoint = _Breakpoint(
    start: 601,
    end: 900,
    name: tablet,
  );
  static const _Breakpoint _desktopBreakPoint = _Breakpoint(
    start: 901,
    end: 1920,
    name: desktop,
  );

  static BoxConstraints horizontalConstraints(final BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return BoxConstraints(
      maxWidth: (width <= _phoneBreakPoint.end)
          ? width / 1.3
          : (width <= _tabletBreakPoint.end)
              ? width / 2
              : 500,
    );
  }
}

@immutable
class _Breakpoint {
  const _Breakpoint({
    required this.start,
    required this.end,
    this.name,
    this.data,
  });
  final double start;
  final double end;
  final String? name;
  final dynamic data;

  _Breakpoint copyWith({
    final double? start,
    final double? end,
    final String? name,
    final dynamic data,
  }) =>
      _Breakpoint(
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
      other is _Breakpoint &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          name == other.name;

  @override
  int get hashCode => start.hashCode * end.hashCode * name.hashCode;
}
