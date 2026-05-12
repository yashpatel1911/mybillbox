import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mybillbox/provider/category_provider.dart';
import 'package:mybillbox/provider/employee_provider.dart';
import 'package:mybillbox/provider/expenses_provider/expense_category_provider.dart';
import 'package:mybillbox/provider/expenses_provider/expense_provider.dart';
import 'package:mybillbox/provider/invoice_provider.dart';
import 'package:mybillbox/provider/product_provider.dart';
import 'package:mybillbox/provider/profile_provider.dart';
import 'package:mybillbox/provider/purchase_provider.dart';
import 'package:provider/provider.dart';
import 'DBHelper/session_manager.dart';
import 'screens/splash_screen.dart';
import '../DBHelper/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  final sessionManager = SessionManager();
  await sessionManager.initPreferences();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => SessionManager()),
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider<InvoiceProvider>(
          create: (_) => InvoiceProvider(),
        ),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseCategoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
      ],
      child: MyBillBoxApp(),
    ),
  );
}

class MyBillBoxApp extends StatelessWidget {
  const MyBillBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MyBillBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.pageBg,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cardBg,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
