class wii {
  static const String app = 'WiRegistro';
  static const String id = 'wiregistro';
  static const String repo = 'wiregistroo';
  static const String desc = 'La mejor app para registrar y dividir gastos con amigos';
  static const int lanzamiento = 2026;
  static const String by = '@wilder.taype';
  static const String link = 'https://wtaype.github.io/';
  static const String version = 'v9.1.1';
}

/** Actualizar main luego esto, pero si es mucho, solo esto. (1)
git tag v9 -m "Version v9" ; git push origin v9

//  ACTUALIZACIÓN PRINCIPAL ONE DEV [START] (2)
git add . ; git commit -m "Actualizacion Principal v9.10.10" ; git push origin main

// En caso de emergencia, para actualizar el Tag existente. (3)
git tag -d v9 ; git tag v9 -m "Version v9 actualizada" ; git push origin v9 --force

flutter clean
flutter pub get
flutter run

Información: 
Inicio -> Donde daremos bienvenida, con gastos y todo lo importante del resumen de semana y eso  
Registrar ->  Donde se registrar los gastos durante el día, mes y todo 
Registros -> Donde se muestra en tabla los registro del wiregistro de forma completa   
Arreglar   -> Donde podemos establecer hasta donde se registro y con 
Ajustes -> como tenemos actualmente.  

 ACTUALIZACION TAG[END] */
