import 'package:flutter/material.dart';
import '../../wicss.dart';
import '../../widev.dart';

class PantallaMensajes extends StatelessWidget {
  const PantallaMensajes({super.key});

  @override
  Widget build(BuildContext context) => WiScaffold(
    title: 'Registros',
    body: Center(
      child: wiCard(
        child: wiPageHeader(
          icon: Icons.receipt_long,
          title: 'Todos los Registros',
          subtitle: 'Ve todos tus gastos en tabla completa 📝',
        ),
      ),
    ),
  );
}
