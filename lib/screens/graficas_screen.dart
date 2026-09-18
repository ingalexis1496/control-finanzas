import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/gasto_provider.dart';
import '../models/gasto_model.dart';

class GraficasScreen extends StatelessWidget {
  const GraficasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gastoProvider = Provider.of<GastoProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    // Fecha actual para tomar el mes y año en curso
    final now = DateTime.now();
    final int mesActual = now.month;
    final int anioActual = now.year;

    const mesesNombres = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final String nombreMesActual = mesesNombres[mesActual];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Estadísticas de $nombreMesActual',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<List<GastoModel>>(
        stream: gastoProvider.obtenerGastosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final todasTransacciones = snapshot.data ?? [];

          // Filtramos solo las transacciones del mes y año actual
          final transaccionesMes = todasTransacciones.where((t) {
            final fechaLocal = t.fecha.toLocal();
            return fechaLocal.month == mesActual &&
                fechaLocal.year == anioActual;
          }).toList();

          if (transaccionesMes.isEmpty) {
            return Center(
              child: Text(
                'No hay movimientos registrados en $nombreMesActual',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          // ==========================================
          // 1. DATOS PARA LA GRÁFICA DE BARRAS (Semanas)
          // ==========================================
          Map<int, List<GastoModel>> semanasDelMesMap = {};
          for (var t in transaccionesMes) {
            int dia = t.fecha.toLocal().day;
            int numeroSemana = ((dia - 1) ~/ 7) + 1;
            semanasDelMesMap.putIfAbsent(numeroSemana, () => []).add(t);
          }
          final semanasKeys = semanasDelMesMap.keys.toList()..sort();

          List<BarChartGroupData> barGroups = [];
          double maxYBar = 0;

          for (int i = 0; i < semanasKeys.length; i++) {
            int numSemana = semanasKeys[i];
            List<GastoModel> items = semanasDelMesMap[numSemana]!;

            double ingresos = items
                .where((t) => t.tipo == 'ingreso')
                .fold(0, (sum, t) => sum + t.monto);
            double gastos = items
                .where((t) => t.tipo == 'gasto')
                .fold(0, (sum, t) => sum + t.monto);

            if (ingresos > maxYBar) maxYBar = ingresos;
            if (gastos > maxYBar) maxYBar = gastos;

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: ingresos,
                    color: const Color(0xFF34D399),
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                  BarChartRodData(
                    toY: gastos,
                    color: const Color(0xFFF87171),
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
                showingTooltipIndicators: [0, 1],
              ),
            );
          }

          // ==========================================
          // 2. DATOS PARA LA GRÁFICA DE TENDENCIA (Día a Día)
          // ==========================================
          // Agrupamos los gastos e ingresos diarios del mes
          Map<int, double> gastosDiarios = {};
          Map<int, double> ingresosDiarios = {};

          for (var t in transaccionesMes) {
            int dia = t.fecha.toLocal().day;
            if (t.tipo == 'gasto') {
              gastosDiarios[dia] = (gastosDiarios[dia] ?? 0) + t.monto;
            } else {
              ingresosDiarios[dia] = (ingresosDiarios[dia] ?? 0) + t.monto;
            }
          }

          List<FlSpot> spotsGastos = [];
          List<FlSpot> spotsIngresos = [];
          double maxYLine = 0;

          // Recorremos los días del 1 al 31 (o el día actual para limpiar)
          int ultimoDiaMes = DateTime(anioActual, mesActual + 1, 0).day;
          for (int dia = 1; dia <= ultimoDiaMes; dia++) {
            double g = gastosDiarios[dia] ?? 0;
            double i = ingresosDiarios[dia] ?? 0;

            if (g > maxYLine) maxYLine = g;
            if (i > maxYLine) maxYLine = i;

            spotsGastos.add(FlSpot(dia.toDouble(), g));
            spotsIngresos.add(FlSpot(dia.toDouble(), i));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TARJETA 1: GRÁFICA DE BARRAS (Semanas) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semanas de $nombreMesActual 📊',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Comportamiento ordenado por semanas del mes',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildLeyendaItem(
                            'Ingresos',
                            const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 16),
                          _buildLeyendaItem('Gastos', const Color(0xFFF87171)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 260,
                        child: BarChart(
                          BarChartData(
                            maxY: maxYBar == 0 ? 100 : maxYBar * 1.35,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) =>
                                    const Color(0xFF0F172A),
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                tooltipMargin: 4,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  String tipoStr = rodIndex == 0
                                      ? 'Ingreso'
                                      : 'Gasto';
                                  return BarTooltipItem(
                                    '$tipoStr\n${currencyFormat.format(rod.toY)}',
                                    TextStyle(
                                      color: rodIndex == 0
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFFF87171),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 &&
                                        index < semanasKeys.length) {
                                      int numeroRealSemana = semanasKeys[index];
                                      int inicioDia =
                                          ((numeroRealSemana - 1) * 7) + 1;
                                      int finDia = numeroRealSemana * 7;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          'Sem $numeroRealSemana\n($inicioDia - ${finDia > 31 ? 31 : finDia})',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 38,
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => const FlLine(
                                color: Color(0xFF334155),
                                strokeWidth: 0.8,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: barGroups,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- TARJETA 2: GRÁFICA DE TENDENCIA (Líneas Día a Día) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tendencia Diaria 📈📉',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Evolución de ingresos y gastos día a día en el mes',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildLeyendaItem(
                            'Ingresos',
                            const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 16),
                          _buildLeyendaItem('Gastos', const Color(0xFFF87171)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 260,
                        child: LineChart(
                          LineChartData(
                            maxY: maxYLine == 0 ? 100 : maxYLine * 1.35,
                            minX: 1,
                            maxX: ultimoDiaMes.toDouble(),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (spot) =>
                                    const Color(0xFF0F172A),
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    String tipo = spot.barIndex == 0
                                        ? 'Gasto'
                                        : 'Ingreso';
                                    Color col = spot.barIndex == 0
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFF34D399);
                                    return LineTooltipItem(
                                      'Día ${spot.x.toInt()}\n$tipo: ${currencyFormat.format(spot.y)}',
                                      TextStyle(
                                        color: col,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5, // Muestra una etiqueta cada 5 días para no saturar
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Día ${value.toInt()}',
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 28,
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => const FlLine(
                                color: Color(0xFF334155),
                                strokeWidth: 0.8,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              // Línea de Gastos (Rojo)
                              LineChartBarData(
                                spots: spotsGastos,
                                isCurved: true,
                                color: const Color(0xFFF87171),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFFF87171)
                                      .withOpacity(0.1),
                                ),
                              ),
                              // Línea de Ingresos (Verde)
                              LineChartBarData(
                                spots: spotsIngresos,
                                isCurved: true,
                                color: const Color(0xFF34D399),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFF34D399)
                                      .withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeyendaItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
