import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/firebase_options.dart';
import 'package:otakunexa/mainscreen.dart';
import 'package:otakunexa/pages/Main/anime_shorts.dart';
import 'package:otakunexa/pages/Main/search_screen.dart';
import 'package:otakunexa/pages/Others/splash_screen.dart';
import 'package:otakunexa/services/api_key_manager.dart';
import 'package:startapp_sdk/startapp.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:otakunexa/services/sassy_ai_service.dart';
import 'package:otakunexa/widgets/sassy_bot_ui.dart';

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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({super.key, required this.apiManager});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 760),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'OtaKuNexa',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          builder: (context, child) {
            SassyAiService.instance.navigatorKey = navigatorKey;
            return ShowCaseWidget(
              builder: (context) => Stack(
                children: [
                  if (child != null) child,
                  const SassyBotUI(),
                ],
              ),
            );
          },
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => SplashScreen(apiManager: apiManager),
            '/home': (context) => MainScreen(apiManager: apiManager),
            '/shorts': (context) => AnimeShortsPage(),
            '/search_programmatic': (context) => const SearchScreen(),
          },
        );
      },
    );
  }
}
