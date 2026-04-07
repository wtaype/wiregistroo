import 'package:flutter/material.dart';
import '../../wicss.dart';
import '../../widev.dart';

class PantallaGastos extends StatelessWidget {
  const PantallaGastos({super.key});

  @override
  Widget build(BuildContext context) => WiScaffold(
    title: 'Registrar',
    body: Center(
      child: wiCard(
        child: wiPageHeader(
          icon: Icons.add_circle_outline,
          title: 'Registrar Gasto',
          subtitle: 'Agrega tus gastos rápidamente 💰',
        ),
      ),
    ),
  );
}
