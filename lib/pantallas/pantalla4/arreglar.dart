// 💳 Pantalla Arreglar - Configurar límites de gastos y presupuestos
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../wicss.dart';
import '../../widev.dart';
import '../../wiauth/auth_fb.dart';
import '../pantalla2/registrar.dart';

// 🔥 MODELO DE LÍMITE _______
class Limite {
  final String id;
  final String usuario;
  final String tipo; // 'diario', 'semanal', 'mensual'
  final double monto;
  final String? categoria; // null = todas las categorías
  final bool activo;
  final Timestamp creado;
  final Timestamp actualizado;

  const Limite({
    required this.id,
    required this.usuario,
    required this.tipo,
    required this.monto,
    this.categoria,
    this.activo = true,
    required this.creado,
    required this.actualizado,
  });

  factory Limite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Limite(
      id: doc.id,
      usuario: data['usuario'] ?? '',
      tipo: data['tipo'] ?? 'mensual',
      monto: (data['monto'] ?? 0).toDouble(),
      categoria: data['categoria'],
      activo: data['activo'] ?? true,
      creado: data['creado'] ?? Timestamp.now(),
      actualizado: data['actualizado'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'usuario': usuario,
        'tipo': tipo,
        'monto': monto,
        'categoria': categoria,
        'activo': activo,
        'creado': creado,
        'actualizado': actualizado,
      };
}

// 🔥 SERVICIO DE LÍMITES _______
class LimitesServicio {
  static final _db = FirebaseFirestore.instance;
  static const _coleccion = 'wilimites';
  static const _cacheKey = 'limites_cache';

  static CollectionReference get _collection => _db.collection(_coleccion);

  // 📊 Obtener límites del usuario
  static Future<List<Limite>> obtenerLimites(String usuario) async {
    try {
      final snapshot = await _collection
          .where('usuario', isEqualTo: usuario)
          .where('activo', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Limite.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo límites: $e');
      return [];
    }
  }

  // 💾 Guardar límite
  static Future<void> guardarLimite(Limite limite) async {
    await _collection.doc(limite.id).set(limite.toFirestore());
  }

  // 🗑️ Eliminar límite
  static Future<void> eliminarLimite(String id) async {
    await _collection.doc(id).update({
      'activo': false,
      'actualizado': Timestamp.now(),
    });
  }

  // 📊 Calcular progreso de gasto vs límite
  static Future<Map<String, dynamic>> calcularProgreso(
    String usuario,
    Limite limite,
  ) async {
    final ahora = DateTime.now();
    DateTime inicio;

    switch (limite.tipo) {
      case 'diario':
        inicio = DateTime(ahora.year, ahora.month, ahora.day);
        break;
      case 'semanal':
        inicio = ahora.subtract(Duration(days: ahora.weekday - 1));
        inicio = DateTime(inicio.year, inicio.month, inicio.day);
        break;
      case 'mensual':
        inicio = DateTime(ahora.year, ahora.month, 1);
        break;
      default:
        inicio = DateTime(ahora.year, ahora.month, 1);
    }

    // Obtener gastos del período
    Query query = FirebaseFirestore.instance
        .collection('wigastos')
        .where('usuario', isEqualTo: usuario)
        .where('activo', isEqualTo: true)
        .where('fechagastos', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio));

    if (limite.categoria != null) {
      query = query.where('categoria', isEqualTo: limite.categoria);
    }

    final snapshot = await query.get();
    final gastos = snapshot.docs.map((doc) => Gasto.fromFirestore(doc)).toList();
    final gastado = gastos.fold<double>(0, (sum, g) => sum + g.monto);

    return {
      'gastado': gastado,
      'limite': limite.monto,
      'porcentaje': limite.monto > 0 ? (gastado / limite.monto) : 0,
      'restante': limite.monto - gastado,
      'excedido': gastado > limite.monto,
    };
  }
}

// 📱 PANTALLA ARREGLAR _______
class PantallaArreglar extends StatefulWidget {
  const PantallaArreglar({super.key});

  @override
  State<PantallaArreglar> createState() => _PantallaArreglarState();
}

class _PantallaArreglarState extends State<PantallaArreglar> {
  List<Limite> _limites = [];
  Map<String, Map<String, dynamic>> _progresos = {};

  @override
  void initState() {
    super.initState();
    _cargarLimites();
  }

  // ⚡ Cargar límites (Background - sin indicador visible)
  Future<void> _cargarLimites() async {
    if (!AuthServicio.estaLogueado) return;

    final usuario = AuthServicio.usuarioActual!.email!.split('@')[0];
    final limites = await LimitesServicio.obtenerLimites(usuario);

    // Calcular progreso de cada límite
    final progresos = <String, Map<String, dynamic>>{};
    for (var limite in limites) {
      progresos[limite.id] = await LimitesServicio.calcularProgreso(usuario, limite);
    }

    if (mounted) {
      setState(() {
        _limites = limites;
        _progresos = progresos;
      });
    }
  }

  // ➕ Agregar límite
  Future<void> _mostrarFormularioLimite([Limite? limiteEditar]) async {
    final resultado = await showDialog<Limite>(
      context: context,
      builder: (context) => _DialogoLimite(limiteEditar: limiteEditar),
    );

    if (resultado != null) {
      await LimitesServicio.guardarLimite(resultado);
      Notificacion.ok(context, limiteEditar == null ? 'Límite creado ✅' : 'Límite actualizado ✅');
      _cargarLimites();
    }
  }

  // 🗑️ Eliminar límite
  Future<void> _eliminarLimite(Limite limite) async {
    final confirmar = await Mensaje(
      context,
      titulo: 'Eliminar Límite',
      msg: '¿Eliminar límite ${limite.tipo} de S/ ${limite.monto.toStringAsFixed(2)}?',
    );

    if (confirmar != true) return;

    setState(() {
      _limites.removeWhere((l) => l.id == limite.id);
      _progresos.remove(limite.id);
    });

    await LimitesServicio.eliminarLimite(limite.id);
    Notificacion.ok(context, 'Límite eliminado');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: wiAppBar('Arreglar', actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarLimites,
            tooltip: 'Sincronizar',
          ),
        ]),
        backgroundColor: AppCSS.bgLight,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _mostrarFormularioLimite(),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Límite'),
          backgroundColor: AppCSS.primary,
          foregroundColor: AppCSS.white,
        ),
        body: RefreshIndicator(
          onRefresh: _cargarLimites,
          color: AppCSS.primary,
          // 🚀 SIN INDICADOR DE CARGA - Siempre muestra contenido
          child: _limites.isEmpty
              ? _vistaVacia()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppCSS.padM,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCSS.gapM,

                      // 📊 Header
                      _headerInfo(),

                      AppCSS.gapL,

                      // 💳 Lista de límites
                      Text(
                        'Mis Límites',
                        style: AppStyle.h3.copyWith(color: AppCSS.textGreen),
                      ),
                      AppCSS.gapM,
                      ..._limites.map((limite) => _cardLimite(limite)),
                    ],
                  ),
                ),
        ),
      );

  // 📊 Header info
  Widget _headerInfo() => Glass(
        child: Column(
          children: [
            Row(
              children: [
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
                AppCSS.gapM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Control de Gastos', style: AppStyle.h3),
                      AppCSS.gapS,
                      Text(
                        'Establece límites para controlar tus gastos',
                        style: AppStyle.bdS.copyWith(color: AppCSS.gray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // 💳 Card de límite
  Widget _cardLimite(Limite limite) {
    final progreso = _progresos[limite.id] ?? {};
    final gastado = (progreso['gastado'] ?? 0.0) as double;
    final porcentaje = (progreso['porcentaje'] ?? 0.0) as double;
    final restante = (progreso['restante'] ?? 0.0) as double;
    final excedido = progreso['excedido'] ?? false;

    final categoria = limite.categoria != null
        ? CategoriaGasto.values.firstWhere(
            (c) => c.key == limite.categoria,
            orElse: () => CategoriaGasto.otros,
          )
        : null;

    return Dismissible(
      key: Key(limite.id),
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
        msg: '¿Eliminar este límite?',
      ),
      onDismissed: (_) => _eliminarLimite(limite),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Glass(
          pad: AppCSS.padM,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (categoria != null) ...[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoria.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppCSS.rad8),
                          ),
                          child: Icon(categoria.icono, color: categoria.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria?.nombre ?? 'Todas las categorías',
                            style: AppStyle.h3,
                          ),
                          Text(
                            'Límite ${limite.tipo}',
                            style: AppStyle.sm.copyWith(color: AppCSS.gray),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'S/ ${limite.monto.toStringAsFixed(2)}',
                    style: AppStyle.h3.copyWith(
                      color: excedido ? AppCSS.error : AppCSS.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              AppCSS.gapM,

              // Barra de progreso
              wiProgress(
                porcentaje.clamp(0.0, 1.0),
                excedido ? AppCSS.error : AppCSS.primary,
                h: 8,
              ),

              AppCSS.gapS,

              // Info de progreso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gastado: S/ ${gastado.toStringAsFixed(2)}',
                    style: AppStyle.bdS.copyWith(
                      color: excedido ? AppCSS.error : AppCSS.text500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    excedido
                        ? 'Excedido: S/ ${(-restante).toStringAsFixed(2)}'
                        : 'Restante: S/ ${restante.toStringAsFixed(2)}',
                    style: AppStyle.bdS.copyWith(
                      color: excedido ? AppCSS.error : AppCSS.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 😢 Vista vacía
  Widget _vistaVacia() => Center(
        child: Padding(
          padding: AppCSS.padL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppCSS.bgSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 60,
                  color: AppCSS.primary,
                ),
              ),
              AppCSS.gapL,
              Text(
                'Sin límites configurados',
                style: AppStyle.h2,
                textAlign: TextAlign.center,
              ),
              AppCSS.gapM,
              Text(
                'Establece límites de gastos para controlar tu presupuesto',
                style: AppStyle.bd.copyWith(color: AppCSS.gray),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// 📝 DIÁLOGO PARA CREAR/EDITAR LÍMITE _______
class _DialogoLimite extends StatefulWidget {
  final Limite? limiteEditar;

  const _DialogoLimite({this.limiteEditar});

  @override
  State<_DialogoLimite> createState() => _DialogoLimiteState();
}

class _DialogoLimiteState extends State<_DialogoLimite> {
  final _formKey = GlobalKey<FormState>();
  final _ctrlMonto = TextEditingController();

  String _tipoSeleccionado = 'mensual';
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    if (widget.limiteEditar != null) {
      _ctrlMonto.text = widget.limiteEditar!.monto.toString();
      _tipoSeleccionado = widget.limiteEditar!.tipo;
      _categoriaSeleccionada = widget.limiteEditar!.categoria;
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
          widget.limiteEditar == null ? 'Nuevo Límite' : 'Editar Límite',
          style: AppStyle.h3,
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monto
                Campo(
                  lbl: 'Monto del límite',
                  hint: '0.00',
                  ico: Icons.attach_money,
                  ctrl: _ctrlMonto,
                  kb: const TextInputType.numberWithOptions(decimal: true),
                  vld: (v) => v == null || v.isEmpty ? 'Ingresa el monto' : null,
                ),
                AppCSS.gapM,

                // Tipo de límite
                Text('Tipo de límite', style: AppStyle.bd),
                AppCSS.gapS,
                Wrap(
                  spacing: 8,
                  children: [
                    _chipTipo('diario', 'Diario'),
                    _chipTipo('semanal', 'Semanal'),
                    _chipTipo('mensual', 'Mensual'),
                  ],
                ),
                AppCSS.gapM,

                // Categoría
                Text('Categoría (opcional)', style: AppStyle.bd),
                AppCSS.gapS,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipCategoria(null, 'Todas', Icons.apps),
                    ...CategoriaGasto.values.map(
                      (cat) => _chipCategoria(cat.key, cat.nombre, cat.icono),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: AppStyle.bdS.copyWith(color: AppCSS.gray)),
          ),
          ElevatedButton(
            onPressed: _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppCSS.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppCSS.rad8),
              ),
            ),
            child: Text(
              widget.limiteEditar == null ? 'Crear' : 'Actualizar',
              style: AppStyle.bdS.copyWith(color: AppCSS.white),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppCSS.rad12),
        ),
      );

  // 🎨 Chip tipo
  Widget _chipTipo(String tipo, String label) {
    final seleccionado = _tipoSeleccionado == tipo;

    return GestureDetector(
      onTap: () => setState(() => _tipoSeleccionado = tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppCSS.primary : AppCSS.white,
          borderRadius: BorderRadius.circular(AppCSS.rad8),
          border: Border.all(
            color: seleccionado ? AppCSS.primary : AppCSS.border,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppStyle.bdS.copyWith(
            color: seleccionado ? AppCSS.white : AppCSS.text500,
            fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 🎨 Chip categoría
  Widget _chipCategoria(String? key, String label, IconData icon) {
    final seleccionado = _categoriaSeleccionada == key;

    return GestureDetector(
      onTap: () => setState(() => _categoriaSeleccionada = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppCSS.primary.withOpacity(0.1) : AppCSS.white,
          borderRadius: BorderRadius.circular(AppCSS.rad8),
          border: Border.all(
            color: seleccionado ? AppCSS.primary : AppCSS.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: seleccionado ? AppCSS.primary : AppCSS.gray),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppStyle.sm.copyWith(
                color: seleccionado ? AppCSS.primary : AppCSS.text500,
                fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💾 Guardar
  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (!AuthServicio.estaLogueado) return;

    final monto = double.tryParse(_ctrlMonto.text.trim());
    if (monto == null || monto <= 0) return;

    final usuario = AuthServicio.usuarioActual!.email!.split('@')[0];
    final ahora = Timestamp.now();

    final limite = Limite(
      id: widget.limiteEditar?.id ?? '${usuario}_${ahora.millisecondsSinceEpoch}',
      usuario: usuario,
      tipo: _tipoSeleccionado,
      monto: monto,
      categoria: _categoriaSeleccionada,
      activo: true,
      creado: widget.limiteEditar?.creado ?? ahora,
      actualizado: ahora,
    );

    Navigator.pop(context, limite);
  }

  @override
  void dispose() {
    _ctrlMonto.dispose();
    super.dispose();
  }
}
