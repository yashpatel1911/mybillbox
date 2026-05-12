import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color.dart';
import 'environment.dart';
import 'package:intl/intl.dart';
class AppConstant {

  static String rupee = '₹';

  static String demo_mode = '';
  static String config_demo_mode = '';
  static String opt_enabled = '';
  static String username = '';
  static String youtubeVideo = '';
  static int notifyOnOff = 0;

  static perPrice(mrp, sellingPrice) {
    double percentageDifference = ((mrp - sellingPrice) / mrp) * 100;
    return percentageDifference.round().toString();
  }

  static couponDisc(price, disc) {
    double discountAmount = (price * disc) / 100;
    print('amountCall : $price === $disc ====== ${price - discountAmount}');
    return price - discountAmount;
  }

  static showDisc(price, disc) {
    double discountAmount = (price * disc) / 100;
    // print('amountCall : $price === $disc ====== $discountAmount');
    return discountAmount.toStringAsFixed(2);
  }

  /* static errorMessage(message, context, {time = 2}) {
    return AnimatedSnackBar.material(
      message,
      duration: Duration(seconds: time),
      type: AnimatedSnackBarType.error,
      desktopSnackBarPosition: DesktopSnackBarPosition.topCenter,
    ).show(context);
  }

  static successMessage(message, context, {time = 2}) {
    return AnimatedSnackBar.material(
      message,
      duration: Duration(seconds: time),
      type: AnimatedSnackBarType.success,
      mobileSnackBarPosition: MobileSnackBarPosition.top,
      desktopSnackBarPosition: DesktopSnackBarPosition.topRight,
    ).show(context);
  }

  static successMessageWithAction(BuildContext context, String message,
      {int time = 3}) {
    return AnimatedSnackBar(
      duration: Duration(seconds: time),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.green[600],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
                child:
                    Text(message, style: const TextStyle(color: Colors.white))),
            TextButton(
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 200));
                if (context.mounted) {
                  Get.offAll(() => UserBottomNavBarPage(initialIndex: 2));
                }
              },
              child: const Text('View cart',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      mobileSnackBarPosition: MobileSnackBarPosition.top,
      desktopSnackBarPosition: DesktopSnackBarPosition.topRight,
    ).show(context);
  }*/

// Enhanced Success Message with Compact Design
  static void successMessage(String message, BuildContext context, {int time = 2}) {
    _show(context, message, time,
        bg: const Color(0xFF0F9D58),
        icon: Icons.check_circle_rounded);
  }

  static void errorMessage(String message, BuildContext context, {int time = 3}) {
    _show(context, message, time,
        bg: const Color(0xFFD32F2F),
        icon: Icons.error_rounded);
  }

  static void infoMessage(String message, BuildContext context, {int time = 2}) {
    _show(context, message, time,
        bg: const Color(0xFF1976D2),
        icon: Icons.info_rounded);
  }

  static void warningMessage(String message, BuildContext context, {int time = 3}) {
    _show(context, message, time,
        bg: const Color(0xFFF57C00),
        icon: Icons.warning_rounded);
  }

  static void _show(
      BuildContext context,
      String message,
      int time, {
        required Color bg,
        required IconData icon,
      }) {
    AnimatedSnackBar(
      duration: Duration(seconds: time),
      builder: (ctx) => Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Accent stripe
                  Container(width: 4, color: bg),
                  // Icon block
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: bg.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: bg, size: 18),
                    ),
                  ),
                  // Message
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Close
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(ctx).hideCurrentSnackBar(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      mobileSnackBarPosition: MobileSnackBarPosition.top,
      desktopSnackBarPosition: DesktopSnackBarPosition.topRight,
      animationCurve: Curves.easeOutCubic,
    ).show(context);
  }

// ---------------------------------------------Date(May 9th, 2024 - May 9th, 2024)Start------------------------------
  static DateTime parseDate(String date) {
    List<String> parts = date.split('/');
    int month = int.parse(parts[0]);
    int day = int.parse(parts[1]);
    int year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  static String formatDateRange(DateTime startDate, DateTime endDate) {
    DateFormat formatter = DateFormat('MMMM d, yyyy');
    return '${formatter.format(startDate)}${getDaySuffix(startDate.day)} - ${formatter.format(endDate)}${getDaySuffix(endDate.day)}';
  }

  static String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

// ---------------------------------------------Date(May 9th, 2024 - May 9th, 2024)End------------------------------

  static String formatDateDMY(String dateStr) {
    DateTime dateTime = DateTime.parse(dateStr);
    String formattedDate = DateFormat('d MMMM yyyy').format(dateTime);
    return formattedDate;
  }

  static String formatDateDMYT(String dateStr) {
    // Handle empty or null-like strings
    if (dateStr.isEmpty || dateStr == 'null') {
      return 'N/A';
    }

    try {
      DateTime dateTime = DateTime.parse(dateStr);
      String formattedDate = DateFormat('d MMMM yyyy, h:mm a').format(dateTime);
      return formattedDate;
    } catch (e) {
      return 'Invalid date';
    }
  }

  static String formatDateOnlyDate(String dateStr) {
    DateTime dateTime = DateTime.parse(dateStr);
    String formattedDate = DateFormat('dMMyy').format(dateTime);
    return formattedDate;
  }

  static String formatDateMD(String dateStr) {
    DateTime dateTime = DateTime.parse(dateStr);
    String formattedDate = DateFormat('MMM d').format(dateTime);
    return formattedDate;
  }

  static String formatDateDM(String dateStr) {
    DateTime dateTime = DateTime.parse(dateStr);
    String formattedDate = DateFormat('d MMM').format(dateTime);
    return formattedDate;
  }

  static String convertTo12HourFormat(String time24Hour) {
    DateTime dateTime = DateFormat("HH:mm").parse(time24Hour);
    String time12Hour = DateFormat("hh:mm a").format(dateTime);
    return time12Hour;
  }

  static String formatDateTime(String dateTimeString) {
    // Parse the string to a DateTime object
    DateTime dateTime = DateTime.parse(dateTimeString);

    // Format the DateTime to only return the time in "hh:mm a" format
    String formattedTime = DateFormat('hh:mm a').format(dateTime);

    return formattedTime;
  }

}
