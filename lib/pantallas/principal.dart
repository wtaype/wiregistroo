import 'package:flutter/material.dart';
import '../wicss.dart';
import 'pantalla1/pantalla1.dart';
import 'pantalla2/pantalla2.dart';
import 'pantalla3/pantalla3.dart';
import 'pantalla4/pantalla4.dart';
import 'pantalla5/pantalla5.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _indiceActual = 0;
  late PageController _pageController;

  final List<Widget> _pantallas = const [
    PantallaRegistrar(),
    PantallaGastos(),
    PantallaMensajes(),
    PantallaArreglar(),
    PantallaConfiguracion(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _indiceActual);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppCSS.verdeClaro,
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
          duration: AppCSS.animacionRapida,
          curve: Curves.easeInOut,
        );
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppCSS.verdePrimario,
      unselectedItemColor: AppCSS.gris,
      selectedLabelStyle: AppEstilos.icoSM.copyWith(
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: AppEstilos.txtSM,
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
          icon: Icon(Icons.verified_outlined),
          activeIcon: Icon(Icons.verified),
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
