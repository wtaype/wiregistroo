// 📊 Pantalla de Registros - Vista completa de todos los gastos con filtros y estadísticas
// 🧠 USA CACHÉ INTELIGENTE - Sin indicadores de carga, velocidad extrema
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../wicss.dart';
import '../../widev.dart';
import '../../wiauth/auth_fb.dart';
import '../../wicache.dart';
import '../pantalla2/registrar.dart'; // Importar Gasto y CategoriaGasto

// 🔥 SERVICIO EXTENDIDO PARA REGISTROS _______
class RegistrosServicio {
  static final _db = FirebaseFirestore.instance;
  static const _coleccion = 'wigastos';
  static CollectionReference get _collection => _db.collection(_coleccion);

  // 📅 Obtener gastos por período (últimos 30 días por defecto)
  static Future<List<Gasto>> obtenerGastosPorPeriodo(
    String usuario, {
    DateTime? inicio,
    DateTime? fin,
    String? categoria,
  }) async {
    try {
      final fechaInicio = inicio ?? DateTime.now().subtract(const Duration(days: 30));
      final fechaFin = fin ?? DateTime.now();

      Query query = _collection
          .where('usuario', isEqualTo: usuario)
          .where('activo', isEqualTo: true)
          .where('fechagastos', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
          .where('fechagastos', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin))
          .orderBy('fechagastos', descending: true);

      // Filtrar por categoría si se especifica
      if (categoria != null && categoria != 'todos') {
        query = _collection
            .where('usuario', isEqualTo: usuario)
            .where('activo', isEqualTo: true)
            .where('categoria', isEqualTo: categoria)
            .where('fechagastos', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
            .where('fechagastos', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin))
            .orderBy('fechagastos', descending: true);
      }

      final snapshot = await query.limit(100).get();
      return snapshot.docs.map((doc) => Gasto.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo gastos: $e');
      return [];
    }
  }

  // 📊 Obtener estadísticas del período
  static Map<String, dynamic> calcularEstadisticas(List<Gasto> gastos) {
    if (gastos.isEmpty) {
      return {
        'total': 0.0,
        'promedio': 0.0,
        'cantidad': 0,
        'categorias': <String, double>{},
      };
    }

    final total = gastos.fold<double>(0, (sum, g) => sum + g.monto);
    final promedio = total / gastos.length;

    // Agrupar por categoría
    final categorias = <String, double>{};
    for (var gasto in gastos) {
      categorias[gasto.categoria] = (categorias[gasto.categoria] ?? 0) + gasto.monto;
    }

    return {
      'total': total,
      'promedio': promedio,
      'cantidad': gastos.length,
      'categorias': categorias,
    };
  }
}

// 📱 PANTALLA REGISTROS _______
class PantallaRegistros extends StatefulWidget {
  const PantallaRegistros({super.key});

  @override
  State<PantallaRegistros> createState() => _PantallaRegistrosState();
}

class _PantallaRegistrosState extends State<PantallaRegistros> {
  List<Gasto> _gastos = [];
  List<Gasto> _gastosFiltrados = [];
  String _categoriaSeleccionada = 'todos';
  String _busqueda = '';
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  Map<String, dynamic> _estadisticas = {};

  final _ctrlBusqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  // ⚡ Cargar gastos (Background - sin indicador visible)
  Future<void> _cargarGastos() async {
    if (!AuthServicio.estaLogueado) return;

    final usuario = AuthServicio.usuarioActual!.email!.split('@')[0];
    final gastos = await RegistrosServicio.obtenerGastosPorPeriodo(
      usuario,
      inicio: _fechaInicio,
      fin: _fechaFin,
      categoria: _categoriaSeleccionada == 'todos' ? null : _categoriaSeleccionada,
    );

    if (mounted) {
      setState(() {
        _gastos = gastos;
        _gastosFiltrados = gastos;
        _estadisticas = RegistrosServicio.calcularEstadisticas(gastos);
      });
      _aplicarFiltros();
    }
  }

  // 🔍 Aplicar filtros de búsqueda
  void _aplicarFiltros() {
    setState(() {
      _gastosFiltrados = _gastos.where((gasto) {
        final coincideBusqueda = _busqueda.isEmpty ||
            gasto.categoria.toLowerCase().contains(_busqueda.toLowerCase()) ||
            (gasto.descripcion?.toLowerCase().contains(_busqueda.toLowerCase()) ?? false);
        return coincideBusqueda;
      }).toList();
      _estadisticas = RegistrosServicio.calcularEstadisticas(_gastosFiltrados);
    });
  }

  // 🗑️ Eliminar gasto
  Future<void> _eliminarGasto(Gasto gasto) async {
    final confirmar = await Mensaje(
      context,
      msg: '¿Eliminar ${gasto.categoria} de S/ ${gasto.monto.toStringAsFixed(2)}?',
    );

    if (confirmar != true) return;

    // 🧠 WICACHE: Eliminar de caché
    WiCache.eliminarGasto(gasto.id);

    setState(() {
      _gastos.removeWhere((g) => g.id == gasto.id);
      _gastosFiltrados.removeWhere((g) => g.id == gasto.id);
      _estadisticas = RegistrosServicio.calcularEstadisticas(_gastosFiltrados);
    });

    Notificacion.ok(context, 'Gasto eliminado');
  }

  // 📅 Seleccionar rango de fechas
  Future<void> _seleccionarRangoFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fechaInicio, end: _fechaFin),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppCSS.primary,
              onPrimary: AppCSS.white,
              surface: AppCSS.white,
              onSurface: AppCSS.text500,
            ),
          ),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() {
        _fechaInicio = rango.start;
        _fechaFin = rango.end;
      });
      _cargarGastos();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: wiAppBar('Registros', actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _seleccionarRangoFechas,
            tooltip: 'Seleccionar fechas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarGastos,
            tooltip: 'Sincronizar',
          ),
        ]),
        backgroundColor: AppCSS.bgLight,
        body: RefreshIndicator(
          onRefresh: _cargarGastos,
          color: AppCSS.primary,
          // 🚀 SIN INDICADOR DE CARGA - Siempre muestra contenido
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppCSS.padM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCSS.gapM,

                // 📊 Estadísticas generales
                _cardEstadisticas(),

                AppCSS.gapL,

                // 🔍 Búsqueda
                _barraBusqueda(),

                AppCSS.gapM,

                // 🏷️ Filtros por categoría
                _filtrosCategorias(),

                AppCSS.gapL,

                // 📋 Lista de gastos
                if (_gastosFiltrados.isEmpty)
                  const Vacio(
                    msg: 'No hay gastos en este período',
                    ico: Icons.search_off,
                  )
                else
                  _listaGastos(),

                AppCSS.gapL,
              ],
            ),
          ),
        ),
      );

  // 📊 Card de estadísticas
  Widget _cardEstadisticas() => Glass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estadísticas', style: AppStyle.h3),
                Text(
                  '${wiFecha(_fechaInicio.toString(), anio: true)} - ${wiFecha(_fechaFin.toString(), anio: true)}',
                  style: AppStyle.sm.copyWith(color: AppCSS.gray),
                ),
              ],
            ),
            AppCSS.gapM,
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    'S/ ${(_estadisticas['total'] ?? 0).toStringAsFixed(2)}',
                    'Total',
                    Icons.account_balance_wallet,
                    AppCSS.primary,
                  ),
                ),
                AppCSS.gapHS,
                Expanded(
                  child: _miniStat(
                    '${_estadisticas['cantidad'] ?? 0}',
                    'Gastos',
                    Icons.receipt,
                    AppCSS.info,
                  ),
                ),
                AppCSS.gapHS,
                Expanded(
                  child: _miniStat(
                    'S/ ${(_estadisticas['promedio'] ?? 0).toStringAsFixed(0)}',
                    'Promedio',
                    Icons.trending_up,
                    AppCSS.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // 📊 Mini stat
  Widget _miniStat(String valor, String label, IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppCSS.rad8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              valor,
              style: AppStyle.bdS.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            Text(label, style: AppStyle.sm, textAlign: TextAlign.center),
          ],
        ),
      );

  // 🔍 Barra de búsqueda
  Widget _barraBusqueda() => TextField(
        controller: _ctrlBusqueda,
        onChanged: (value) {
          setState(() => _busqueda = value);
          _aplicarFiltros();
        },
        style: AppStyle.bd,
        decoration: InputDecoration(
          hintText: 'Buscar por categoría o descripción...',
          prefixIcon: const Icon(Icons.search, color: AppCSS.primary),
          suffixIcon: _busqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppCSS.gray),
                  onPressed: () {
                    _ctrlBusqueda.clear();
                    setState(() => _busqueda = '');
                    _aplicarFiltros();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppCSS.rad12),
            borderSide: BorderSide(color: AppCSS.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppCSS.rad12),
            borderSide: const BorderSide(color: AppCSS.primary, width: 2),
          ),
          filled: true,
          fillColor: AppCSS.white,
        ),
      );

  // 🏷️ Filtros de categorías
  Widget _filtrosCategorias() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chipFiltro('todos', 'Todas', Icons.apps, AppCSS.text500),
            ...CategoriaGasto.values.map(
              (cat) => _chipFiltro(cat.key, cat.nombre, cat.icono, cat.color),
            ),
          ],
        ),
      );

  // 🎨 Chip filtro
  Widget _chipFiltro(String key, String label, IconData icon, Color color) {
    final seleccionado = _categoriaSeleccionada == key;

    return GestureDetector(
      onTap: () {
        setState(() => _categoriaSeleccionada = key);
        _cargarGastos();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? color : AppCSS.white,
          borderRadius: BorderRadius.circular(AppCSS.rad12),
          border: Border.all(
            color: seleccionado ? color : AppCSS.border,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: seleccionado ? AppCSS.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
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

  // 📋 Lista de gastos
  Widget _listaGastos() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_gastosFiltrados.length} Gastos',
            style: AppStyle.h3.copyWith(color: AppCSS.textGreen),
          ),
          AppCSS.gapM,
          ..._agruparPorFecha(_gastosFiltrados).entries.map((entry) {
            return _seccionFecha(entry.key, entry.value);
          }),
        ],
      );

  // 📅 Agrupar gastos por fecha
  Map<String, List<Gasto>> _agruparPorFecha(List<Gasto> gastos) {
    final agrupados = <String, List<Gasto>>{};
    for (var gasto in gastos) {
      final fecha = gasto.fechagastos.toDate();
      final key = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      agrupados[key] = [...(agrupados[key] ?? []), gasto];
    }
    return agrupados;
  }

  // 📅 Sección por fecha
  Widget _seccionFecha(String fecha, List<Gasto> gastos) {
    final totalDia = gastos.fold<double>(0, (sum, g) => sum + g.monto);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppCSS.bgSoft,
            borderRadius: BorderRadius.circular(AppCSS.rad8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wiFecha(fecha, anio: true),
                style: AppStyle.bd.copyWith(
                  color: AppCSS.textGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'S/ ${totalDia.toStringAsFixed(2)}',
                style: AppStyle.bd.copyWith(
                  color: AppCSS.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ...gastos.map((gasto) => _itemGasto(gasto)),
        AppCSS.gapM,
      ],
    );
  }

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
        margin: const EdgeInsets.only(bottom: 8),
        padding: AppCSS.padL,
        decoration: BoxDecoration(
          color: AppCSS.error,
          borderRadius: BorderRadius.circular(AppCSS.rad12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: AppCSS.white, size: 24),
      ),
      confirmDismiss: (_) => Mensaje(context, msg: '¿Eliminar este gasto?'),
      onDismissed: (_) => _eliminarGasto(gasto),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Glass(
          pad: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: categoria.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppCSS.rad8),
                ),
                child: Icon(categoria.icono, color: categoria.color, size: 22),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoria.nombre, style: AppStyle.bd),
                    if (gasto.descripcion != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        gasto.descripcion!,
                        style: AppStyle.bdS.copyWith(color: AppCSS.gray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
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

  // 🕐 Formatear hora
  String _formatearHora(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  @override
  void dispose() {
    _ctrlBusqueda.dispose();
    super.dispose();
  }
}
