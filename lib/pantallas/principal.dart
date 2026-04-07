import 'package:flutter/material.dart';
import '../wicss.dart';
import 'pantalla1/inicio.dart'; // Importar inicio.dart
import 'pantalla2/registrar.dart'; // Importar registrar.dart
import 'pantalla3/registros.dart'; // Importar registros.dart
import 'pantalla4/arreglar.dart'; // Importar arreglar.dart
import 'pantalla5/pantalla5.dart'; // Ajustes

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _indiceActual = 0; // 🏠 Empezar en Inicio
  late PageController _pageController;

  final List<Widget> _pantallas = const [
    PantallaInicio(), // Pantalla 1 - Inicio
    PantallaRegistrar(), // Pantalla 2 - Registrar (NUEVA)
    PantallaRegistros(), // Pantalla 3 - Registros
    PantallaArreglar(), // Pantalla 4 - Arreglar
    PantallaConfiguracion(), // Pantalla 5 - Ajustes
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _indiceActual);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppCSS.bgLight,
    body: PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _indiceActual = index),
      children: _pantallas,
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _indiceActual,
      onTap: (index) {
        setState(() => _indiceActual = index);
        _pageController.animateToPage(
          index,
          duration: AppCSS.trans1,
          curve: Curves.easeInOut,
        );
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppCSS.primary,
      unselectedItemColor: AppCSS.gray,
      selectedLabelStyle: AppStyle.lbl.copyWith(
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: AppStyle.sm,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Registrar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Registros',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.build_outlined),
          activeIcon: Icon(Icons.build),
          label: 'Arreglar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Ajustes',
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
