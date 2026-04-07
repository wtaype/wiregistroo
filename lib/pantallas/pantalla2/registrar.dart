// ⚡ Sistema de gastos con RENDIMIENTO EXTREMO: Optimistic UI + Cache + Background operations
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../wicss.dart';
import '../../widev.dart';
import '../../wiauth/auth_fb.dart';
import '../../wicache.dart'; // 🧠 CACHE INTELIGENTE

// 🗄️ MODELO DE GASTO _______
class Gasto {
  final String id;
  final double monto;
  final String categoria;
  final String? descripcion;
  final String usuario;
  final String correo;
  final List<String> participantes;
  final Timestamp fechagastos;
  final Timestamp fechaCreado;
  final Timestamp fechaActualizado;
  final String actualizadoPor;
  final String color;
  final String icono;
  final String grupo;
  final bool activo;

  const Gasto({
    required this.id,
    required this.monto,
    required this.categoria,
    this.descripcion,
    required this.usuario,
    required this.correo,
    required this.participantes,
    required this.fechagastos,
    required this.fechaCreado,
    required this.fechaActualizado,
    required this.actualizadoPor,
    required this.color,
    required this.icono,
    required this.grupo,
    this.activo = true,
  });

  // 🔥 Desde Firestore
  factory Gasto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gasto(
      id: doc.id,
      monto: (data['monto'] ?? 0).toDouble(),
      categoria: data['categoria'] ?? 'otros',
      descripcion: data['descripcion'],
      usuario: data['usuario'] ?? '',
      correo: data['correo'] ?? '',
      participantes: List<String>.from(data['participantes'] ?? []),
      fechagastos: data['fechagastos'] ?? Timestamp.now(),
      fechaCreado: data['fechaCreado'] ?? Timestamp.now(),
      fechaActualizado: data['fechaActualizado'] ?? Timestamp.now(),
      actualizadoPor: data['actualizadoPor'] ?? '',
      color: data['color'] ?? '#00BCD4',
      icono: data['icono'] ?? 'more_horiz',
      grupo: data['grupo'] ?? '',
      activo: data['activo'] ?? true,
    );
  }

  // 🔥 A Firestore
  Map<String, dynamic> toFirestore() => {
        'monto': monto,
        'categoria': categoria,
        'descripcion': descripcion,
        'usuario': usuario,
        'correo': correo,
        'participantes': participantes,
        'fechagastos': fechagastos,
        'fechaCreado': fechaCreado,
        'fechaActualizado': fechaActualizado,
        'actualizadoPor': actualizadoPor,
        'color': color,
        'icono': icono,
        'grupo': grupo,
        'activo': activo,
      };

  // 🔥 A Map para cache
  Map<String, dynamic> toMap() => {
        'id': id,
        'monto': monto,
        'categoria': categoria,
        'descripcion': descripcion,
        'usuario': usuario,
        'correo': correo,
        'participantes': participantes,
        'fechagastos': fechagastos.millisecondsSinceEpoch,
        'fechaCreado': fechaCreado.millisecondsSinceEpoch,
        'fechaActualizado': fechaActualizado.millisecondsSinceEpoch,
        'actualizadoPor': actualizadoPor,
        'color': color,
        'icono': icono,
        'grupo': grupo,
        'activo': activo,
      };

  // 🔥 Desde Map (cache)
  factory Gasto.fromMap(Map<String, dynamic> data) => Gasto(
        id: data['id'] ?? '',
        monto: (data['monto'] ?? 0).toDouble(),
        categoria: data['categoria'] ?? 'otros',
        descripcion: data['descripcion'],
        usuario: data['usuario'] ?? '',
        correo: data['correo'] ?? '',
        participantes: List<String>.from(data['participantes'] ?? []),
        fechagastos: Timestamp.fromMillisecondsSinceEpoch(
          data['fechagastos'] ?? DateTime.now().millisecondsSinceEpoch,
        ),
        fechaCreado: Timestamp.fromMillisecondsSinceEpoch(
          data['fechaCreado'] ?? DateTime.now().millisecondsSinceEpoch,
        ),
        fechaActualizado: Timestamp.fromMillisecondsSinceEpoch(
          data['fechaActualizado'] ?? DateTime.now().millisecondsSinceEpoch,
        ),
        actualizadoPor: data['actualizadoPor'] ?? '',
        color: data['color'] ?? '#00BCD4',
        icono: data['icono'] ?? 'more_horiz',
        grupo: data['grupo'] ?? '',
        activo: data['activo'] ?? true,
      );
}

// 🎨 CATEGORÍAS PREDEFINIDAS _______
enum CategoriaGasto {
  comida(
    key: 'comida',
    nombre: 'Comida',
    color: AppCSS.bg1,
    icono: Icons.restaurant,
  ),
  transporte(
    key: 'transporte',
    nombre: 'Transporte',
    color: AppCSS.bg2,
    icono: Icons.directions_car,
  ),
  entretenimiento(
    key: 'entretenimiento',
    nombre: 'Diversión',
    color: AppCSS.bg3,
    icono: Icons.movie,
  ),
  salud(
    key: 'salud',
    nombre: 'Salud',
    color: AppCSS.bg4,
    icono: Icons.favorite,
  ),
  compras(
    key: 'compras',
    nombre: 'Compras',
    color: AppCSS.bg5,
    icono: Icons.shopping_bag,
  ),
  otros(
    key: 'otros',
    nombre: 'Otros',
    color: AppCSS.bg6,
    icono: Icons.more_horiz,
  );

  final String key;
  final String nombre;
  final Color color;
  final IconData icono;

  const CategoriaGasto({
    required this.key,
    required this.nombre,
    required this.color,
    required this.icono,
  });

  String get colorHex =>
      '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  String get iconoNombre => icono.toString().split('(').last.split(')').first;
}

// 🔥 SERVICIO DE GASTOS CON CACHE _______
class GastosServicio {
  static final _db = FirebaseFirestore.instance;
  static const _coleccion = 'wigastos';
  static const _cacheKey = 'gastos_cache';
  static const _cacheFechaKey = 'gastos_cache_fecha';
  static const _tiempoExpiracion = Duration(minutes: 5);

  static CollectionReference get _collection => _db.collection(_coleccion);

  // ⚡ Generar ID único
  static String generarId(String usuario) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return '${usuario}_$timestamp';
  }

  // ⚡ Guardar gasto (OPTIMISTIC - devuelve inmediatamente)
  static Future<void> guardarGasto(Gasto gasto) async {
    // Guardar en Firebase en background (no esperar)
    _collection.doc(gasto.id).set(gasto.toFirestore()).catchError((e) {
      print('❌ Error guardando gasto: $e');
    });
  }

  // ⚡ Obtener gastos del día (CON CACHE)
  static Future<List<Gasto>> obtenerGastosHoy(String usuario) async {
    try {
      // Cache primero
      final gastosCache = await _obtenerDeCache();
      if (gastosCache.isNotEmpty && await _cacheValido()) {
        print('📱 CACHE: ${gastosCache.length} gastos');
        return gastosCache;
      }

      // Firebase si no hay cache
      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
      final finHoy = inicioHoy.add(const Duration(days: 1));

      final query = await _collection
          .where('usuario', isEqualTo: usuario)
          .where('activo', isEqualTo: true)
          .where('fechagastos',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy))
          .where('fechagastos', isLessThan: Timestamp.fromDate(finHoy))
          .orderBy('fechagastos', descending: true)
          .get();

      final gastos = query.docs.map((doc) => Gasto.fromFirestore(doc)).toList();

      // Guardar en cache
      await _guardarEnCache(gastos);

      print('🌐 FIREBASE: ${gastos.length} gastos');
      return gastos;
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  // ⚡ Eliminar gasto (SOFT DELETE)
  static Future<void> eliminarGasto(String id) async {
    _collection.doc(id).update({
      'activo': false,
      'fechaActualizado': Timestamp.now(),
    }).catchError((e) {
      print('❌ Error eliminando: $e');
    });
  }

  // 💾 Cache helpers
  static Future<void> _guardarEnCache(List<Gasto> gastos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gastosJson = gastos.map((g) => g.toMap()).toList();
      await prefs.setString(_cacheKey, jsonEncode(gastosJson));
      await prefs.setString(_cacheFechaKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  static Future<List<Gasto>> _obtenerDeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gastosJson = prefs.getString(_cacheKey);
      if (gastosJson == null) return [];

      final List<dynamic> decoded = jsonDecode(gastosJson);
      return decoded.map((data) => Gasto.fromMap(data)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> _cacheValido() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fechaStr = prefs.getString(_cacheFechaKey);
      if (fechaStr == null) return false;

      final fecha = DateTime.parse(fechaStr);
      return DateTime.now().difference(fecha) < _tiempoExpiracion;
    } catch (_) {
      return false;
    }
  }

  static Future<void> limpiarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheFechaKey);
    } catch (_) {}
  }
}

// 📱 PANTALLA REGISTRAR _______
class PantallaRegistrar extends StatefulWidget {
  const PantallaRegistrar({super.key});

  @override
  State<PantallaRegistrar> createState() => _PantallaRegistrarState();
}

class _PantallaRegistrarState extends State<PantallaRegistrar> {
  final _formKey = GlobalKey<FormState>();
  final _ctrlMonto = TextEditingController();
  final _ctrlDescripcion = TextEditingController();

  CategoriaGasto _categoriaSeleccionada = CategoriaGasto.comida;
  List<Gasto> _gastos = [];
  double _totalHoy = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatosInstantaneos();
    _sincronizarBackground();
  }

  // ⚡ INSTANTÁNEO: Carga datos desde caché en memoria
  void _cargarDatosInstantaneos() {
    final gastos = WiCache.obtenerGastosHoySync();
    setState(() {
      _gastos = gastos;
      _totalHoy = gastos.fold(0, (sum, g) => sum + g.monto);
    });
  }

  // 🔄 BACKGROUND: Sincroniza con Firestore sin bloquear UI
  Future<void> _sincronizarBackground() async {
    if (!AuthServicio.estaLogueado) return;

    await WiCache.sincronizarBackground(
      onGastosActualizados: (gastos) {
        if (mounted) {
          setState(() {
            _gastos = gastos;
            _totalHoy = gastos.fold(0, (sum, g) => sum + g.monto);
          });
        }
      },
    );
  }

  // ⚡ Guardar gasto (OPTIMISTIC UI + WICACHE)
  Future<void> _guardarGasto() async {
    if (!_formKey.currentState!.validate()) return;
    if (!AuthServicio.estaLogueado) return;

    final monto = double.tryParse(_ctrlMonto.text.trim());
    if (monto == null || monto <= 0) {
      Notificacion.err(context, 'Ingresa un monto válido');
      return;
    }

    final user = AuthServicio.usuarioActual!;
    final usuario = user.email!.split('@')[0];
    final correo = user.email!;
    final ahora = Timestamp.now();

    // Crear gasto
    final nuevoGasto = Gasto(
      id: GastosServicio.generarId(usuario),
      monto: monto,
      categoria: _categoriaSeleccionada.key,
      descripcion: _ctrlDescripcion.text.trim().isEmpty
          ? null
          : _ctrlDescripcion.text.trim(),
      usuario: usuario,
      correo: correo,
      participantes: [usuario],
      fechagastos: ahora,
      fechaCreado: ahora,
      fechaActualizado: ahora,
      actualizadoPor: correo,
      color: _categoriaSeleccionada.colorHex,
      icono: _categoriaSeleccionada.iconoNombre,
      grupo: 'genial',
      activo: true,
    );

    // 🧠 WICACHE: Agregar a caché (actualiza memoria + local + Firestore en background)
    WiCache.agregarGasto(nuevoGasto);

    // 🚀 OPTIMISTIC UI: Actualizar lista local
    setState(() {
      _gastos.insert(0, nuevoGasto);
      _totalHoy += monto;
    });

    // Limpiar form
    _ctrlMonto.clear();
    _ctrlDescripcion.clear();

    Notificacion.ok(context, 'Gasto registrado ⚡');
  }

  // 🗑️ Eliminar gasto (OPTIMISTIC + WICACHE)
  Future<void> _eliminarGasto(Gasto gasto) async {
    final confirmar = await Mensaje(
      context,
      msg: '¿Eliminar ${gasto.categoria} de S/ ${gasto.monto.toStringAsFixed(2)}?',
    );

    if (confirmar != true) return;

    // 🧠 WICACHE: Eliminar de caché (actualiza memoria + local + Firestore en background)
    WiCache.eliminarGasto(gasto.id);

    // 🚀 OPTIMISTIC: Eliminar de la lista inmediatamente
    setState(() {
      _gastos.removeWhere((g) => g.id == gasto.id);
      _totalHoy -= gasto.monto;
    });

    Notificacion.ok(context, 'Gasto eliminado');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: wiAppBar('Registrar', actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _sincronizarBackground,
            tooltip: 'Sincronizar',
          ),
        ]),
        backgroundColor: AppCSS.bgLight,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _mostrarFormulario,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Gasto'),
          backgroundColor: AppCSS.primary,
          foregroundColor: AppCSS.white,
        ),
        body: RefreshIndicator(
          onRefresh: _sincronizarBackground,
          color: AppCSS.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppCSS.padM,
            child: Column(
              children: [
                AppCSS.gapM,

                // 📊 Resumen del día
                _resumenDia(),

                AppCSS.gapL,

                // 📋 Lista de gastos (SIN indicador de carga)
                if (_gastos.isEmpty)
                  const Vacio(
                    msg: 'Sin gastos hoy\n¡Agrega tu primer gasto!',
                    ico: Icons.receipt_long,
                  )
                else
                  _listaGastos(),
              ],
            ),
          ),
        ),
      );

  // 📊 Resumen del día
  Widget _resumenDia() => Glass(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wiDia(), style: AppStyle.bdS.copyWith(color: AppCSS.gray)),
                    AppCSS.gapS,
                    Text(
                      'S/ ${_totalHoy.toStringAsFixed(2)}',
                      style: AppStyle.h1.copyWith(color: AppCSS.primary),
                    ),
                  ],
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppCSS.bgSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppCSS.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
            AppCSS.gapM,
            Row(
              children: [
                Expanded(
                  child: wiStat(
                    '${_gastos.length}',
                    'Gastos',
                    Icons.receipt,
                    AppCSS.info,
                    vertical: false,
                  ),
                ),
                AppCSS.gapHS,
                Expanded(
                  child: wiStat(
                    _totalHoy > 0
                        ? 'S/ ${(_totalHoy / _gastos.length).toStringAsFixed(0)}'
                        : 'S/ 0',
                    'Promedio',
                    Icons.trending_up,
                    AppCSS.warning,
                    vertical: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // 📋 Lista de gastos
  Widget _listaGastos() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastos de Hoy',
            style: AppStyle.h3.copyWith(color: AppCSS.textGreen),
          ),
          AppCSS.gapM,
          ..._gastos.map((gasto) => _itemGasto(gasto)),
        ],
      );

  // 💳 Item de gasto
  Widget _itemGasto(Gasto gasto) {
    final categoria = CategoriaGasto.values.firstWhere(
      (c) => c.key == gasto.categoria,
      orElse: () => CategoriaGasto.otros,
    );

    return Dismissible(
      key: Key(gasto.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppCSS.padL,
        decoration: BoxDecoration(
          color: AppCSS.error,
          borderRadius: BorderRadius.circular(AppCSS.rad12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: AppCSS.white, size: 28),
      ),
      confirmDismiss: (_) => Mensaje(
        context,
        msg: '¿Eliminar este gasto?',
      ),
      onDismissed: (_) => _eliminarGasto(gasto),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Glass(
          pad: AppCSS.padM,
          child: Row(
            children: [
              // Icono categoría
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: categoria.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppCSS.rad8),
                ),
                child: Icon(categoria.icono, color: categoria.color, size: 24),
              ),
              AppCSS.gapM,

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoria.nombre, style: AppStyle.h3),
                    if (gasto.descripcion != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        gasto.descripcion!,
                        style: AppStyle.bdS.copyWith(color: AppCSS.gray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _formatearHora(gasto.fechagastos),
                      style: AppStyle.sm.copyWith(color: AppCSS.gray),
                    ),
                  ],
                ),
              ),

              // Monto
              Text(
                'S/ ${gasto.monto.toStringAsFixed(2)}',
                style: AppStyle.h3.copyWith(
                  color: categoria.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 Mostrar formulario
  void _mostrarFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppCSS.bgLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nuevo Gasto', style: AppStyle.h2),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                AppCSS.gapL,

                // Monto
                Campo(
                  lbl: 'Monto',
                  hint: '0.00',
                  ico: Icons.attach_money,
                  ctrl: _ctrlMonto,
                  kb: const TextInputType.numberWithOptions(decimal: true),
                  vld: (v) =>
                      v == null || v.isEmpty ? 'Ingresa el monto' : null,
                ),
                AppCSS.gapM,

                // Categorías
                Text('Categoría', style: AppStyle.bd),
                AppCSS.gapS,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoriaGasto.values
                      .map((cat) => _chipCategoria(cat))
                      .toList(),
                ),
                AppCSS.gapM,

                // Descripción
                Campo(
                  lbl: 'Descripción (opcional)',
                  hint: 'Ej: Almuerzo con amigos',
                  ico: Icons.notes,
                  ctrl: _ctrlDescripcion,
                ),
                AppCSS.gapL,

                // Botón
                SizedBox(
                  width: double.infinity,
                  child: Btn(
                    txt: 'Guardar Gasto',
                    ico: Icons.save,
                    onTap: () {
                      _guardarGasto();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 Chip de categoría
  Widget _chipCategoria(CategoriaGasto cat) {
    final seleccionado = _categoriaSeleccionada == cat;

    return GestureDetector(
      onTap: () => setState(() => _categoriaSeleccionada = cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? cat.color : AppCSS.white,
          borderRadius: BorderRadius.circular(AppCSS.rad12),
          border: Border.all(
            color: seleccionado ? cat.color : AppCSS.border,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cat.icono,
              color: seleccionado ? AppCSS.white : cat.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              cat.nombre,
              style: AppStyle.bdS.copyWith(
                color: seleccionado ? AppCSS.white : AppCSS.text500,
                fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🕐 Formatear hora
  String _formatearHora(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  @override
  void dispose() {
    _ctrlMonto.dispose();
    _ctrlDescripcion.dispose();
    super.dispose();
  }
}
