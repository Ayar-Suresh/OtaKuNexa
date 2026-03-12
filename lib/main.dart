import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/firebase_options.dart';
import 'package:otakunexa/mainscreen.dart';
import 'package:otakunexa/pages/Main/anime_shorts.dart';
import 'package:otakunexa/pages/Others/splash_screen.dart';
import 'package:otakunexa/services/api_key_manager.dart';
import 'package:startapp_sdk/startapp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase initialized successfully');

  // 1. Initialize the SDK instance
  var startAppSdk = StartAppSdk();

  // 3. Create your API Manager
  final apiKeyManager = ApiKeyManager();

  runApp(MyApp(apiManager: apiKeyManager));
}

class MyApp extends StatelessWidget {
  final ApiKeyManager apiManager;
  const MyApp({super.key, required this.apiManager});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 760),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'OtaKuNexa',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => SplashScreen(apiManager: apiManager),
            '/home': (context) => MainScreen(apiManager: apiManager),
            '/shorts': (context) => AnimeShortsPage(),
          },
        );
      },
    );
  }
}
