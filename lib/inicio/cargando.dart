import 'package:flutter/material.dart';
import '../wicss.dart';
import '../wiauth/login.dart';
import '../wiauth/auth_fb.dart';
import '../pantallas/principal.dart';

class PantallaCargando extends StatefulWidget {
  const PantallaCargando({super.key});

  @override
  State<PantallaCargando> createState() => _PantallaCargandoState();
}

class _PantallaCargandoState extends State<PantallaCargando> {
  @override
  void initState() {
    super.initState();
    // Saltar a la pantalla correcta tan pronto como sea posible
    Future.microtask(() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AuthServicio.estaLogueado
              ? const PantallaPrincipal()
              : const PantallaLogin(),
          transitionDuration: const Duration(milliseconds: 120),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppCSS.bgLight,
    body: Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(AppCSS.white),
          backgroundColor: AppCSS.primary,
        ),
      ),
    ),
  );
}
