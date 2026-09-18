import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/gasto_provider.dart';
import '../models/gasto_model.dart';

class HistorialSemanasScreen extends StatelessWidget {
  const HistorialSemanasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gastoProvider = Provider.of<GastoProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: const Color(
        0xFF0B0F19,
      ), // Fondo ultra oscuro sofisticado
      appBar: AppBar(
        title: const Text(
          'Historial Financiero 🏛️',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<GastoModel>>(
        stream: gastoProvider.obtenerGastosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final transacciones = snapshot.data ?? [];

          if (transacciones.isEmpty) {
            return const Center(
              child: Text(
                'No hay registros históricos aún.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
              ),
            );
          }

          Map<String, List<GastoModel>> semanasMap = {};
          for (var t in transacciones) {
            semanasMap.putIfAbsent(t.idSemana, () => []).add(t);
          }

          Map<String, List<GastoModel>> mesesMap = {};
          for (var t in transacciones) {
            const meses = [
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
            String mesNombre = meses[t.fecha.month - 1];
            String mesAnioKey = '$mesNombre ${t.fecha.year}';
            mesesMap.putIfAbsent(mesAnioKey, () => []).add(t);
          }

          final semanasKeys = semanasMap.keys.toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumen Global por Meses 📅',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...mesesMap.entries.map((entry) {
                          String mesKey = entry.key;
                          List<GastoModel> itemsMes = entry.value;

                          double ingresosMes = itemsMes
                              .where((t) => t.tipo == 'ingreso')
                              .fold(0, (sum, i) => sum + i.monto);
                          double gastosMes = itemsMes
                              .where((t) => t.tipo == 'gasto')
                              .fold(0, (sum, i) => sum + i.monto);
                          double balanceMes = ingresosMes - gastosMes;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF334155),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                                const BoxShadow(
                                  color: Color(0x1AFFFFFF),
                                  blurRadius: 1,
                                  offset: Offset(0, -1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        mesKey,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.shield_moon_outlined,
                                      color: Color(0xFF38BDF8),
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Ingresos:',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              currencyFormat.format(
                                                ingresosMes,
                                              ),
                                              style: const TextStyle(
                                                color: Color(0xFF34D399),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Gastos:',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              currencyFormat.format(gastosMes),
                                              style: const TextStyle(
                                                color: Color(0xFFF87171),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(
                                    color: Color(0xFF334155),
                                    height: 1,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Neto del Mes:',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          currencyFormat.format(balanceMes),
                                          style: TextStyle(
                                            color: balanceMes >= 0
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFFF87171),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 10),
                        const Text(
                          'Desglose Detallado por Semanas ⚡',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...semanasKeys.map((semanaKey) {
                          List<GastoModel> itemsSemana = semanasMap[semanaKey]!;

                          double ingresosSemana = itemsSemana
                              .where((t) => t.tipo == 'ingreso')
                              .fold(0, (sum, item) => sum + item.monto);

                          double gastosSemana = itemsSemana
                              .where((t) => t.tipo == 'gasto')
                              .fold(0, (sum, item) => sum + item.monto);

                          double balanceSemana = ingresosSemana - gastosSemana;

                          // TARJETA SEMANAL CON GESTURE DETECTOR PARA NAVEGAR AL DETALLE
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetalleSemanaScreen(
                                    semanaKey: semanaKey,
                                    transaccionesSemana: itemsSemana,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF334155),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                  const BoxShadow(
                                    color: Color(0x12FFFFFF),
                                    blurRadius: 1,
                                    offset: Offset(0, -1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          semanaKey,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF38BDF8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: balanceSemana >= 0
                                              ? const Color(0xFF064E3B)
                                              : const Color(0xFF7F1D1D),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: balanceSemana >= 0
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'Neto: ${currencyFormat.format(balanceSemana)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: balanceSemana >= 0
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFFFCA5A5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(
                                      color: Color(0xFF334155),
                                      height: 1,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Ingresos:',
                                              style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                currencyFormat.format(
                                                  ingresosSemana,
                                                ),
                                                style: const TextStyle(
                                                  color: Color(0xFF34D399),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Gastos:',
                                              style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                currencyFormat.format(
                                                  gastosSemana,
                                                ),
                                                style: const TextStyle(
                                                  color: Color(0xFFF87171),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total de movimientos: ${itemsSemana.length}',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 11,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// PANTALLA DE DETALLE DE LA SEMANA
// ==========================================
class DetalleSemanaScreen extends StatelessWidget {
  final String semanaKey;
  final List<GastoModel> transaccionesSemana;

  const DetalleSemanaScreen({
    super.key,
    required this.semanaKey,
    required this.transaccionesSemana,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: Text(
          semanaKey,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transaccionesSemana.length,
        itemBuilder: (context, index) {
          final item = transaccionesSemana[index];
          final isIngreso = item.tipo == 'ingreso';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.concepto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(item.fecha),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIngreso ? '+' : '-'}${currencyFormat.format(item.monto)}',
                  style: TextStyle(
                    color: isIngreso
                        ? const Color(0xFF34D399)
                        : const Color(0xFFF87171),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
