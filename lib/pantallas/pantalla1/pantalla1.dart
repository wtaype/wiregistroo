import 'package:flutter/material.dart';
import '../../wicss.dart';
import '../../widev.dart';

class PantallaRegistrar extends StatelessWidget {
  const PantallaRegistrar({super.key});

  @override
  Widget build(BuildContext context) => WiScaffold(
    title: 'Inicio',
    body: Center(
      child: wiCard(
        child: wiPageHeader(
          icon: Icons.home,
          title: 'Bienvenido a Inicio',
          subtitle: 'Dashboard de gastos y resumen semanal 📊',
        ),
      ),
    ),
  );
}
