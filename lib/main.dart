import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/discover_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'core/image_db.dart';

void main() async {
  // ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // initialize Firebase with the generated options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ImageDB.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وصال',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(fontFamily: 'Cairo', primarySwatch: Colors.amber),
      // no need for an extra Directionality here since each screen is already RTL
      initialRoute: '/sign-in',
      routes: {
        '/sign-in': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const DiscoverScreen(),
      },
    );
  }
}
