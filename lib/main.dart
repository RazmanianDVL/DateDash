// Updated main.dart with new professional theme
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
// ... rest of your main.dart ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // your firebase init etc.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'DateDash',
          debugShowCheckedModeBanner: false,
          theme: dateDashTheme,
          home: const YourStartingScreen(),
        );
      },
    );
  }
}
