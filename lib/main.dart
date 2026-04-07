import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // 🔥 AGREGAR
import 'firebase_options.dart'; // 🔥 AGREGAR
import 'inicio/cargando.dart';
import 'wicss.dart';
import 'wii.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 INICIALIZAR FIREBASE ANTES DE TODO
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppCSS.bgLight,
      systemNavigationBarColor: AppCSS.bgLight,
    ),
  );
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: wii.app,
      debugShowCheckedModeBanner: false,
      theme: AppStyle.tema,
      home: const PantallaCargando(),
    );
  }
}
