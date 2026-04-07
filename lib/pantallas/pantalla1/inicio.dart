// 🏠 Pantalla Inicio - Dashboard con resumen de gastos y estadísticas
// 🧠 USA CACHÉ INTELIGENTE - Sin indicadores de carga, velocidad extrema
import 'package:flutter/material.dart';
import '../../wicss.dart';
import '../../widev.dart';
import '../../wiauth/auth_fb.dart';
import '../../wicache.dart';
import '../pantalla2/registrar.dart';

// 📱 PANTALLA INICIO _______
// 🧠 Cache-first: muestra datos inmediatamente, sincroniza en background
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  // 🧠 Datos desde caché - SIEMPRE disponibles instantáneamente
  Map<String, dynamic> _estadisticas = {};
  List<Gasto> _gastosRecientes = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosInstantaneos();
    _sincronizarBackground();
  }

  // ⚡ INSTANTÁNEO: Carga datos desde caché en memoria
  void _cargarDatosInstantaneos() {
    setState(() {
      _estadisticas = WiCache.obtenerEstadisticasSync();
      _gastosRecientes = WiCache.obtenerGastosRecientesSync();
    });
  }

  // 🔄 BACKGROUND: Sincroniza con Firestore sin bloquear UI
  Future<void> _sincronizarBackground() async {
    if (!AuthServicio.estaLogueado) return;

    await WiCache.sincronizarBackground(
      onEstadisticasActualizadas: (stats) {
        if (mounted) setState(() => _estadisticas = stats);
      },
      onRecientesActualizados: (recientes) {
        if (mounted) setState(() => _gastosRecientes = recientes);
      },
    );
  }

  // 🔄 Pull to refresh - fuerza sincronización
  Future<void> _refrescar() async {
    await _sincronizarBackground();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: wiAppBar('Inicio', actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescar,
            tooltip: 'Sincronizar',
          ),
        ]),
        backgroundColor: AppCSS.bgLight,
        body: RefreshIndicator(
          onRefresh: _refrescar,
          color: AppCSS.primary,
          // 🚀 SIN INDICADOR DE CARGA - Siempre muestra contenido
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppCSS.padM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCSS.gapM,

                // 👋 Saludo
                _cardBienvenida(),

                AppCSS.gapL,

                // 📊 Resumen de la semana
                _cardResumenSemana(),

                AppCSS.gapL,

                // 📈 Gastos por categoría
                _seccionCategorias(),

                AppCSS.gapL,

                // 📋 Gastos recientes
                _seccionGastosRecientes(),

                AppCSS.gapL,
              ],
            ),
          ),
        ),
      );

  // 👋 Card de bienvenida
  Widget _cardBienvenida() {
    final usuario = AuthServicio.usuarioActual?.email?.split('@')[0] ?? 'Usuario';

    return Glass(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: AppCSS.gradGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.waving_hand, color: AppCSS.white, size: 32),
          ),
          AppCSS.gapM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Saludar(), style: AppStyle.h3),
                AppCSS.gapS,
                Text(
                  '@$usuario',
                  style: AppStyle.bd.copyWith(
                    color: AppCSS.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wiDia(),
                  style: AppStyle.sm.copyWith(color: AppCSS.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📊 Card resumen de la semana
  Widget _cardResumenSemana() {
    final total = (_estadisticas['total'] ?? 0.0) as double;
    final cantidad = _estadisticas['cantidad'] ?? 0;
    final promedio = (_estadisticas['promedio'] ?? 0.0) as double;

    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Resumen de la Semana', style: AppStyle.h3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppCSS.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppCSS.rad8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppCSS.primary),
                    const SizedBox(width: 4),
                    Text(
                      '7 días',
                      style: AppStyle.sm.copyWith(
                        color: AppCSS.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppCSS.gapL,

          // Total gastado
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppCSS.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppCSS.rad8),
                ),
                child: const Icon(Icons.account_balance_wallet, color: AppCSS.primary, size: 24),
              ),
              AppCSS.gapM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Gastado', style: AppStyle.bdS.copyWith(color: AppCSS.gray)),
                    Text(
                      'S/ ${total.toStringAsFixed(2)}',
                      style: AppStyle.h2.copyWith(
                        color: AppCSS.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppCSS.gapM,

          // Stats
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  '$cantidad',
                  'Gastos',
                  Icons.receipt,
                  AppCSS.info,
                ),
              ),
              AppCSS.gapHS,
              Expanded(
                child: _miniStat(
                  'S/ ${promedio.toStringAsFixed(0)}',
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
  }

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

  // 📈 Sección de categorías
  Widget _seccionCategorias() {
    // Convertir de forma segura el Map dinámico a Map<String, double>
    final rawMap = _estadisticas['porCategoria'];
    final porCategoria = <String, double>{};
    if (rawMap is Map) {
      rawMap.forEach((key, value) {
        porCategoria[key.toString()] = (value is num) ? value.toDouble() : 0.0;
      });
    }

    if (porCategoria.isEmpty) return const SizedBox.shrink();

    // Ordenar categorías por monto
    final categorias = porCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalGastado = (_estadisticas['total'] ?? 0.0) as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gastos por Categoría',
          style: AppStyle.h3.copyWith(color: AppCSS.textGreen),
        ),
        AppCSS.gapM,
        ...categorias.take(3).map((entry) {
          final categoria = CategoriaGasto.values.firstWhere(
            (c) => c.key == entry.key,
            orElse: () => CategoriaGasto.otros,
          );
          final porcentaje = totalGastado > 0 ? entry.value / totalGastado : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Glass(
              pad: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(categoria.nombre, style: AppStyle.bd),
                            Text(
                              '${(porcentaje * 100).toStringAsFixed(0)}% del total',
                              style: AppStyle.sm.copyWith(color: AppCSS.gray),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'S/ ${entry.value.toStringAsFixed(2)}',
                        style: AppStyle.h3.copyWith(
                          color: categoria.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  AppCSS.gapS,
                  wiProgress(porcentaje, categoria.color, h: 6),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // 📋 Sección gastos recientes
  Widget _seccionGastosRecientes() {
    if (_gastosRecientes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gastos Recientes',
          style: AppStyle.h3.copyWith(color: AppCSS.textGreen),
        ),
        AppCSS.gapM,
        ..._gastosRecientes.take(5).map((gasto) => _itemGasto(gasto)),
      ],
    );
  }

  // 💳 Item de gasto
  Widget _itemGasto(Gasto gasto) {
    final categoria = CategoriaGasto.values.firstWhere(
      (c) => c.key == gasto.categoria,
      orElse: () => CategoriaGasto.otros,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Glass(
        pad: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icono
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
                      style: AppStyle.sm.copyWith(color: AppCSS.gray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    wiFecha(gasto.fechagastos.toDate().toString(), anio: true),
                    style: AppStyle.sm.copyWith(color: AppCSS.gray),
                  ),
                ],
              ),
            ),

            // Monto
            Text(
              'S/ ${gasto.monto.toStringAsFixed(2)}',
              style: AppStyle.bd.copyWith(
                color: categoria.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
