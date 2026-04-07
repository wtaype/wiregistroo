class wii {
  static const String app = 'WiRegistro';
  static const String id = 'wiregistro';
  static const String repo = 'wiregistroo';
  static const String desc = 'La mejor app para registrar y dividir gastos con amigos';
  static const int lanzamiento = 2026;
  static const String by = '@wilder.taype';
  static const String link = 'https://wtaype.github.io/';
  static const String version = 'v11.1.1';
}

/**  ACTUALIZACIÓN PRINCIPAL ONE DEV [MAIN] (1)
git add . ; git commit -m "Actualizacion Principal v11.10.10" ; git push origin main

//  Actualizar versiones de seguridad [TAG NUEVO] (2)
git tag v11 -m "Version v11" ; git push origin v11

// Actualizar versiones de seguridad [TAG REMPLAZO] (2)
git tag -d v11 ; git tag v11 -m "Version v11 actualizada" ; git push origin v11 --force

flutter clean
flutter pub get
flutter run

Información: 
Inicio -> Donde daremos bienvenida, con gastos y todo lo importante del resumen de semana y eso  
Registrar ->  Donde se registrar los gastos durante el día, mes y todo 
Registros -> Donde se muestra en tabla los registro del wiregistro de forma completa   
Arreglar   -> Donde podemos establecer hasta donde se registro y con 
Ajustes -> como tenemos actualmente.  

Pantalla Inicio → Resumen semanal/mensual
Pantalla Registrar → Formulario rápido + lista de gastos del día
Pantalla Registros → Tabla/lista completa con filtros
Pantalla Arreglar → Ajustes de grupo y divisiones
Pantalla Ajustes → Ya la tienes perfecta

 ACTUALIZACION TAG[END] */
