// 🧠 WICACHE - Sistema de Caché Inteligente para WiRegistro
// Cache-first + Background sync = Velocidad extrema sin indicadores de carga
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantallas/pantalla2/registrar.dart';
import 'wiauth/auth_fb.dart';

// 🔄 Singleton de caché global
class WiCache {
  static final WiCache _instance = WiCache._internal();
  factory WiCache() => _instance;
  WiCache._internal();

  // 🗄️ Instancia de SharedPreferences
  static SharedPreferences? _prefs;
  
  // 📦 Caché en memoria (ultra rápido)
  static List<Gasto> _gastosMemoria = [];
  static Map<String, dynamic> _estadisticasMemoria = {};
  static List<Gasto> _gastosRecientesMemoria = [];
  static DateTime? _ultimaActualizacion;
  
  // 🔧 Keys
  static const _keyGastos = 'wi_gastos_v2';
  static const _keyEstadisticas = 'wi_estadisticas_v2';
  static const _keyGastosRecientes = 'wi_gastos_recientes_v2';
  static const _keyUltimaSync = 'wi_ultima_sync';
  
  // ⚡ Inicializar caché (llamar en main.dart)
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _cargarMemoriaDesdeLocal();
    print('🧠 WiCache inicializado');
  }
  
  // 📥 Cargar de SharedPreferences a memoria
  static Future<void> _cargarMemoriaDesdeLocal() async {
    try {
      // Gastos
      final gastosJson = _prefs?.getString(_keyGastos);
      if (gastosJson != null) {
        final List decoded = jsonDecode(gastosJson);
        _gastosMemoria = decoded.map((d) => Gasto.fromMap(d)).toList();
      }
      
      // Estadísticas
      final statsJson = _prefs?.getString(_keyEstadisticas);
      if (statsJson != null) {
        _estadisticasMemoria = Map<String, dynamic>.from(jsonDecode(statsJson));
      }
      
      // Gastos recientes
      final recientesJson = _prefs?.getString(_keyGastosRecientes);
      if (recientesJson != null) {
        final List decoded = jsonDecode(recientesJson);
        _gastosRecientesMemoria = decoded.map((d) => Gasto.fromMap(d)).toList();
      }
      
      // Última sync
      final syncStr = _prefs?.getString(_keyUltimaSync);
      if (syncStr != null) {
        _ultimaActualizacion = DateTime.parse(syncStr);
      }
      
      print('📦 Memoria cargada: ${_gastosMemoria.length} gastos');
    } catch (e) {
      print('❌ Error cargando memoria: $e');
    }
  }
  
  // 💾 Guardar en SharedPreferences
  static Future<void> _guardarLocal() async {
    try {
      // Gastos
      final gastosJson = jsonEncode(_gastosMemoria.map((g) => g.toMap()).toList());
      await _prefs?.setString(_keyGastos, gastosJson);
      
      // Estadísticas (convertir para JSON)
      final statsToSave = Map<String, dynamic>.from(_estadisticasMemoria);
      statsToSave['porCategoria'] = Map<String, double>.from(statsToSave['porCategoria'] ?? {});
      await _prefs?.setString(_keyEstadisticas, jsonEncode(statsToSave));
      
      // Gastos recientes
      final recientesJson = jsonEncode(_gastosRecientesMemoria.map((g) => g.toMap()).toList());
      await _prefs?.setString(_keyGastosRecientes, recientesJson);
      
      // Última sync
      await _prefs?.setString(_keyUltimaSync, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Error guardando local: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🚀 API PRINCIPAL - Cache-first con background sync
  // ═══════════════════════════════════════════════════════════════
  
  /// Obtiene gastos de hoy instantáneamente desde caché
  /// y sincroniza con Firestore en background
  static List<Gasto> obtenerGastosHoySync() => _gastosMemoria;
  
  /// Obtiene estadísticas de la semana instantáneamente
  static Map<String, dynamic> obtenerEstadisticasSync() => _estadisticasMemoria;
  
  /// Obtiene gastos recientes instantáneamente
  static List<Gasto> obtenerGastosRecientesSync() => _gastosRecientesMemoria;
  
  /// Agrega un gasto al caché y sincroniza con Firestore en background
  static void agregarGasto(Gasto gasto) {
    // 1. Agregar a memoria inmediatamente
    _gastosMemoria.insert(0, gasto);
    
    // 2. Actualizar estadísticas inmediatamente
    _recalcularEstadisticas();
    
    // 3. Actualizar recientes
    _gastosRecientesMemoria.insert(0, gasto);
    if (_gastosRecientesMemoria.length > 5) {
      _gastosRecientesMemoria = _gastosRecientesMemoria.take(5).toList();
    }
    
    // 4. Guardar en local (background)
    _guardarLocal();
    
    // 5. Guardar en Firestore (background, sin esperar)
    _guardarEnFirestore(gasto);
  }
  
  /// Elimina un gasto del caché y de Firestore
  static void eliminarGasto(String id) {
    // 1. Remover de memoria
    _gastosMemoria.removeWhere((g) => g.id == id);
    _gastosRecientesMemoria.removeWhere((g) => g.id == id);
    
    // 2. Recalcular estadísticas
    _recalcularEstadisticas();
    
    // 3. Guardar local
    _guardarLocal();
    
    // 4. Soft delete en Firestore (background)
    _eliminarEnFirestore(id);
  }
  
  /// Sincroniza con Firestore en background
  /// Retorna callback para actualizar UI cuando termine
  static Future<void> sincronizarBackground({
    Function(List<Gasto>)? onGastosActualizados,
    Function(Map<String, dynamic>)? onEstadisticasActualizadas,
    Function(List<Gasto>)? onRecientesActualizados,
  }) async {
    if (!AuthServicio.estaLogueado) return;
    
    final usuario = AuthServicio.usuarioActual!.email!.split('@')[0];
    final db = FirebaseFirestore.instance;
    
    try {
      // 📊 Cargar estadísticas de la semana
      final ahora = DateTime.now();
      final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
      final inicioSemanaDate = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
      
      final queryStats = await db
          .collection('wigastos')
          .where('usuario', isEqualTo: usuario)
          .where('activo', isEqualTo: true)
          .where('fechagastos', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemanaDate))
          .get();
      
      final gastosSemana = queryStats.docs.map((doc) => Gasto.fromFirestore(doc)).toList();
      final total = gastosSemana.fold<double>(0, (sum, g) => sum + g.monto);
      
      final porCategoria = <String, double>{};
      for (var gasto in gastosSemana) {
        porCategoria[gasto.categoria] = (porCategoria[gasto.categoria] ?? 0) + gasto.monto;
      }
      
      _estadisticasMemoria = {
        'total': total,
        'cantidad': gastosSemana.length,
        'promedio': gastosSemana.isNotEmpty ? total / gastosSemana.length : 0.0,
        'porCategoria': porCategoria,
      };
      
      // 📅 Cargar gastos de hoy
      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
      final finHoy = inicioHoy.add(const Duration(days: 1));
      
      final queryHoy = await db
          .collection('wigastos')
          .where('usuario', isEqualTo: usuario)
          .where('activo', isEqualTo: true)
          .where('fechagastos', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy))
          .where('fechagastos', isLessThan: Timestamp.fromDate(finHoy))
          .orderBy('fechagastos', descending: true)
          .get();
      
      _gastosMemoria = queryHoy.docs.map((doc) => Gasto.fromFirestore(doc)).toList();
      
      // 📋 Cargar gastos recientes
      final queryRecientes = await db
          .collection('wigastos')
          .where('usuario', isEqualTo: usuario)
          .where('activo', isEqualTo: true)
          .orderBy('fechagastos', descending: true)
          .limit(5)
          .get();
      
      _gastosRecientesMemoria = queryRecientes.docs.map((doc) => Gasto.fromFirestore(doc)).toList();
      
      // 💾 Guardar en local
      _ultimaActualizacion = DateTime.now();
      await _guardarLocal();
      
      // 🔔 Callbacks para actualizar UI
      onGastosActualizados?.call(_gastosMemoria);
      onEstadisticasActualizadas?.call(_estadisticasMemoria);
      onRecientesActualizados?.call(_gastosRecientesMemoria);
      
      print('🔄 Sync completado: ${_gastosMemoria.length} gastos hoy');
    } catch (e) {
      print('❌ Error sync: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🔧 Helpers internos
  // ═══════════════════════════════════════════════════════════════
  
  static void _recalcularEstadisticas() {
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicioSemanaDate = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
    
    // Filtrar gastos de la semana actual
    final gastosSemana = _gastosMemoria.where((g) {
      final fechaGasto = g.fechagastos.toDate();
      return fechaGasto.isAfter(inicioSemanaDate) || fechaGasto.isAtSameMomentAs(inicioSemanaDate);
    }).toList();
    
    // Calcular total
    final total = gastosSemana.fold<double>(0, (sum, g) => sum + g.monto);
    
    // Agrupar por categoría
    final porCategoria = <String, double>{};
    for (var gasto in gastosSemana) {
      porCategoria[gasto.categoria] = (porCategoria[gasto.categoria] ?? 0) + gasto.monto;
    }
    
    _estadisticasMemoria = {
      'total': total,
      'cantidad': gastosSemana.length,
      'promedio': gastosSemana.isNotEmpty ? total / gastosSemana.length : 0.0,
      'porCategoria': porCategoria,
    };
  }
  
  static Future<void> _guardarEnFirestore(Gasto gasto) async {
    try {
      await FirebaseFirestore.instance
          .collection('wigastos')
          .doc(gasto.id)
          .set(gasto.toFirestore());
      print('☁️ Gasto guardado en Firestore');
    } catch (e) {
      print('❌ Error guardando en Firestore: $e');
    }
  }
  
  static Future<void> _eliminarEnFirestore(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('wigastos')
          .doc(id)
          .update({
        'activo': false,
        'fechaActualizado': Timestamp.now(),
      });
      print('☁️ Gasto eliminado en Firestore');
    } catch (e) {
      print('❌ Error eliminando en Firestore: $e');
    }
  }
  
  /// Limpia todo el caché (usar en logout)
  static Future<void> limpiar() async {
    _gastosMemoria.clear();
    _estadisticasMemoria.clear();
    _gastosRecientesMemoria.clear();
    _ultimaActualizacion = null;
    
    await _prefs?.remove(_keyGastos);
    await _prefs?.remove(_keyEstadisticas);
    await _prefs?.remove(_keyGastosRecientes);
    await _prefs?.remove(_keyUltimaSync);
    
    print('🗑️ Caché limpiado');
  }
  
  /// Verifica si el caché necesita sincronización
  static bool necesitaSync() {
    if (_ultimaActualizacion == null) return true;
    return DateTime.now().difference(_ultimaActualizacion!) > const Duration(minutes: 2);
  }
  
  /// Obtiene tiempo desde última sync
  static String tiempoDesdeSync() {
    if (_ultimaActualizacion == null) return 'Nunca';
    final diff = DateTime.now().difference(_ultimaActualizacion!);
    if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    return 'Hace ${diff.inHours}h';
  }
}
