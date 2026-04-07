import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🎨 COLORES Y DISEÑO - TEMA VERDE v2 _______
class AppCSS {
  // 🖼️ ASSETS _______
  static const String lgPath = 'assets/images/logo.png';
  static const String logoSmile = 'assets/images/smile.png';
  
  static Widget get logo => Image.asset(
    lgPath, width: 80, height: 80, fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, size: 80, color: primary),
  );

  static Widget get logoCircular => Container(
    width: 80, height: 80,
    decoration: BoxDecoration(
      shape: BoxShape.circle, color: white,
      boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: ClipOval(child: logo),
  );

  // 🎨 PRINCIPALES _______
  static const Color primary = Color(0xFF4CAF50);   // Verde principal
  static const Color secondary = Color(0xFF81C784); // Verde secundario
  static const Color bgLight = Color(0xFFB9F6CA);   // Fondo claro
  static const Color bgSoft = Color(0xFFE8F5E8);    // Fondo suave
  static const Color bgDark = Color(0xFF388E3C);    // Verde oscuro
  static const Color white = Colors.white;          // Blanco
  static const Color black = Color(0xFF000000);     // Negro
  static const Color gray = Color(0xFF9E9E9E);      // Gris
  static const Color grayLight = Color(0xFFF5F5F5); // Gris claro
  static const Color grayDark = Color(0xFF424242);  // Gris oscuro
  static const Color border = Color(0xFFB9F6CA);    // Borde
  static const Color inputBg = Color(0xFFF5FFF6);   // Input fondo
  static const Color clear = Colors.transparent;    // Transparente

  // 📝 TEXTOS _______
  static const Color text = Color(0xFF000000);     // Texto base
  static const Color text700 = Color(0xFF1A1A1A);  // Texto oscuro
  static const Color text500 = Color(0xFF2E2E2E);  // Texto medio
  static const Color text300 = Color(0xFF666666);  // Texto claro
  static const Color textGreen = Color(0xFF388E3C); // Texto verde

  // ✅ ESTADOS _______
  static const Color success = Color(0xFF4CAF50); // Éxito
  static const Color error = Color(0xFFE53935);   // Error
  static const Color warning = Color(0xFFFF9800); // Alerta
  static const Color info = Color(0xFF2196F3);    // Info

  // 🧩 CATEGORÍAS (gastos) bg1-bg6 _______
  static const Color bg1 = Color(0xFF4CAF50); // Comida
  static const Color bg2 = Color(0xFF2196F3); // Transporte
  static const Color bg3 = Color(0xFF9C27B0); // Entretenimiento
  static const Color bg4 = Color(0xFFFF5722); // Salud
  static const Color bg5 = Color(0xFFFFB300); // Compras
  static const Color bg6 = Color(0xFF00BCD4); // Otros

  // 🌈 GRADIENTES _______
  static const LinearGradient gradGreen = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient gradSoft = LinearGradient(
    colors: [Color(0xFFB9F6CA), Color(0xFF4CAF50)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // 📐 ESPACIADOS _______
  static const double sp8 = 8.0;
  static const double sp16 = 16.0;
  static const double sp24 = 24.0;

  // 📐 RADIOS _______
  static const double rad8 = 8.0;
  static const double rad12 = 12.0;
  static const double rad16 = 16.0;
  static const double rad20 = 20.0;

  // ⏱️ TRANSICIONES trans1-trans3 _______
  static const Duration trans1 = Duration(milliseconds: 300); // Rápida
  static const Duration trans2 = Duration(milliseconds: 600); // Lenta
  static const Duration trans3 = Duration(seconds: 3);        // Carga

  // 📱 PADDINGS _______
  static const EdgeInsets padM = EdgeInsets.symmetric(vertical: 9, horizontal: 10);
  static const EdgeInsets padL = EdgeInsets.symmetric(vertical: 15, horizontal: 20);

  // 📏 GAPS _______
  static Widget get gapS => const SizedBox(height: sp8);
  static Widget get gapM => const SizedBox(height: sp16);
  static Widget get gapL => const SizedBox(height: sp24);
  static Widget get gapHS => const SizedBox(width: sp8);
  static Widget get gapHM => const SizedBox(width: sp16);

  // 🪟 GLASS glass300-glass700 (300=ligero, 700=intenso) _______
  static BoxDecoration get glass300 => BoxDecoration(
    gradient: LinearGradient(
      colors: [bgSoft.withOpacity(0.6), white.withOpacity(0.3)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(rad20),
    border: Border.all(color: white.withOpacity(0.4), width: 1.5),
    boxShadow: [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, 10))],
  );
  
  static BoxDecoration get glass500 => BoxDecoration(
    color: white.withOpacity(0.7),
    borderRadius: BorderRadius.circular(rad16),
    border: Border.all(color: border.withOpacity(0.5)),
    boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
  );
  
  static BoxDecoration get glass700 => BoxDecoration(
    color: white.withOpacity(0.85),
    borderRadius: BorderRadius.circular(rad20),
    border: Border.all(color: border.withOpacity(0.7), width: 1.5),
    boxShadow: [BoxShadow(color: black.withOpacity(0.08), blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 8))],
  );

  // 🌫️ SOMBRAS shadow _______
  static List<BoxShadow> get shadow => [
    BoxShadow(color: primary.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
  ];

  // 🔲 BORDES borderBox _______
  static BoxDecoration get borderBox => BoxDecoration(
    color: inputBg, borderRadius: BorderRadius.circular(rad12),
    border: Border.all(color: border),
  );
}

// 🎭 ESTILOS DE TEXTO v2 _______
class AppStyle {
  // 🎨 TEMA APP _______
  static ThemeData get tema => ThemeData(
    scaffoldBackgroundColor: AppCSS.bgLight,
    primarySwatch: Colors.green,
    fontFamily: GoogleFonts.poppins().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: AppCSS.primary, foregroundColor: AppCSS.white,
      elevation: 0, toolbarHeight: 45,
      titleTextStyle: btn, centerTitle: true,
      iconTheme: const IconThemeData(color: AppCSS.white, size: 22),
      shadowColor: AppCSS.primary.withOpacity(0.3),
    ),
    textTheme: TextTheme(
      headlineLarge: h1,
      headlineMedium: h2,
      titleLarge: h3,
      bodyLarge: bd,
      bodyMedium: bdS,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppCSS.primary, foregroundColor: AppCSS.white,
        textStyle: btn,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCSS.rad12)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white, selectedItemColor: AppCSS.primary,
      unselectedItemColor: AppCSS.gray, elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  // 📝 TEXTOS _______
  static TextStyle get h1 => _p(32, FontWeight.w600, AppCSS.textGreen);
  static TextStyle get h2 => _p(24, FontWeight.w600, AppCSS.textGreen);
  static TextStyle get h3 => _p(18, FontWeight.w600, AppCSS.text700);
  static TextStyle get bd => _p(16, FontWeight.w500, AppCSS.text500);
  static TextStyle get bdS => _p(14, FontWeight.w500, AppCSS.text500);
  static TextStyle get lbl => _p(13, FontWeight.w500, AppCSS.text300);
  static TextStyle get sm => _p(11, FontWeight.w500, AppCSS.text300);
  static TextStyle get btn => _p(16, FontWeight.w600, AppCSS.white);

  // 🔧 HELPER _______
  static TextStyle _p(double sz, FontWeight w, Color c) =>
      GoogleFonts.poppins(fontSize: sz, fontWeight: w, color: c);
}

// 🎨 VALIDACIÓN _______
class VdError {
  static const Color borde = Color(0xFFE53935);
  static const Color texto = Color(0xFFD32F2F);
  static const Color fondo = Color(0xFFFFEBEE);
  static const Color icono = Color(0xFFE53935);
}

class VdGreen {
  static const Color borde = Color(0xFF4CAF50);
  static const Color texto = Color(0xFF2E7D32);
  static const Color fondo = Color(0xFFE8F5E8);
  static const Color icono = Color(0xFF4CAF50);
}
