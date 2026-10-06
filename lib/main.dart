import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/routes/app_routes.dart';
import 'ui/theme.dart';
import 'widgets/phone_frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CheapEatsApp());
}

class CheapEatsApp extends StatelessWidget {
  const CheapEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheapEats',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // No Chrome, permite arrastar listas e carrosséis com o mouse (como no celular).
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onGenerateInitialRoutes: AppRoutes.onGenerateInitialRoutes,
      builder: (context, child) => PhoneFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
