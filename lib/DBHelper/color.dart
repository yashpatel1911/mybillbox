import 'package:flutter/material.dart';

extension colors on ColorScheme {
  static MaterialColor primary_app = const MaterialColor(
    0xff002557,
    <int, Color>{
      50: primary,
      100: primary,
      200: primary,
      300: primary,
      400: primary,
      500: primary,
      600: primary,
      700: primary,
      800: primary,
      900: primary,
    },
  );

  static const Color primary = Color(0xff002557);
  static const Color secondary = Color(0xff002557);
  static const Color drawer = Color(0xffa0a9e3);
  static const Color card_primary = Color(0xffd0dcfa);

  //change
  static const Color whiteBack = Color(0xfff5f6f8);
  // static const Color whiteBack = Color(0xffeeeff1);
  static const Color stockBack = Color(0xffFEE1B7);
  static const Color blackBox = Color(0xff2F2F2F);
  static const Color whiteBox = Color.fromARGB(255, 233, 233, 233);
  // static const Color blackBox = Color(0xff1D1B20);
  static const Color blackSettingBox = Color(0xff2F2F2F);
  static const Color commodityBack = Color(0xffE9D4F5);
  static const Color appbar = Color(0xffDFF0FC);
  static const Color redSad = Color(0xffDE0E40);
  static const Color blueLight = Color(0xffecedee);
  static const Color blueOp = Color(0xffecedee);

  Color get btnColor => brightness == Brightness.dark ? whiteTemp : primary;

  Color get changeablePrimary => brightness == Brightness.dark
      ? const Color(0xff00113B)
      : const Color(0xff08153f);

  Color get lightWhite =>
      brightness == Brightness.dark ? darkColor : const Color(0xffEEF2F9);

  Color get blue => brightness == Brightness.dark
      ? const Color(0xff00113B)
      : const Color(0xff08153f);

  Color get fontColor =>
      brightness == Brightness.dark ? whiteTemp : const Color(0xff222222);

  Color get gray =>
      brightness == Brightness.dark ? darkColor3 : const Color(0xfff0f0f0);

  Color get simmerBase =>
      brightness == Brightness.dark ? darkColor2 : Colors.grey[300]!;

  Color get simmerHigh =>
      brightness == Brightness.dark ? darkColor : Colors.grey[100]!;

  static Color darkIcon = const Color(0xff9B9B9B);

  static const Color grad1Color = Color(0xff9cd1ec);
  static const Color grad2Color = Color(0xff4543C1);
  static const Color lightWhite2 = Color(0xffEEF2F3);

  static const Color yellow = Color(0xfffdd901);

  static const Color red = Colors.red;

  Color get lightBlack =>
      brightness == Brightness.dark ? whiteTemp : const Color(0xff52575C);

  Color get lightBlack2 =>
      brightness == Brightness.dark ? white70 : const Color(0xff999999);

  static const Color darkColor = Color(0xff181616);
  static const Color darkColor2 = Color(0xff252525);
  static const Color darkColor3 = Color(0xffa0a1a0);

  Color get white =>
      brightness == Brightness.dark ? darkColor2 : const Color(0xffFFFFFF);
  static const Color whiteTemp = Color(0xffFFFFFF);

  Color get black =>
      brightness == Brightness.dark ? whiteTemp : const Color(0xff000000);

  static const Color white10 = Colors.white10;
  static const Color white30 = Colors.white30;
  static const Color white70 = Colors.white70;

  static const Color black54 = Colors.black54;
  static const Color black12 = Colors.black12;
  static const Color disableColor = Color(0xffEEF2F9);

  static const Color blackTemp = Color(0xff000000);

  Color get black26 => brightness == Brightness.dark ? white30 : Colors.black54;
  static const Color cardColor = Color(0xffFFFFFF);
}
