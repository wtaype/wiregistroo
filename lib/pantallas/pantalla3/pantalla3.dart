import 'package:flutter/material.dart';
import '../../wicss.dart';
import '../../widev.dart';

class PantallaArreglar extends StatelessWidget {
  const PantallaArreglar({super.key});

  @override
  Widget build(BuildContext context) => WiScaffold(
    title: 'Arreglar',
    body: Center(
      child: wiCard(
        child: wiPageHeader(
          icon: Icons.verified,
          title: 'Configurar Límites',
          subtitle: 'Establece límites de gastos y controla tu presupuesto 💳',
        ),
      ),
    ),
  );
}
