import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_check_config.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/conectividade_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await ConectividadeService.instance.iniciar();

  try {
    await ThemeController.instance.carregar();
  } catch (_) {
    // Mantém o tema do sistema se a preferência local não estiver disponível.
  }

  final androidToken = AppCheckConfig.androidDebugToken.isEmpty
      ? null
      : AppCheckConfig.androidDebugToken;
  final webToken = AppCheckConfig.webDebugToken.isEmpty
      ? null
      : AppCheckConfig.webDebugToken;

  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerWeb: WebDebugProvider(debugToken: webToken),
    );
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidDebugProvider(debugToken: androidToken),
    );
  }

  runApp(const PassaporteApp());
}

class PassaporteApp extends StatelessWidget {
  const PassaporteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Passaporte',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.modo,
          themeAnimationDuration: const Duration(milliseconds: 280),
          themeAnimationCurve: Curves.easeInOut,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthGate(),
        );
      },
    );
  }
}
