import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/gasto_provider.dart';
import '../models/gasto_model.dart';

class DetalleSemanaScreen extends StatelessWidget {
  final String idSemana;
  final String tituloSemana;

  const DetalleSemanaScreen({
    super.key,
    required this.idSemana,
    required this.tituloSemana,
  });

  @override
  Widget build(BuildContext context) {
    final gastoProvider = Provider.of<GastoProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          tituloSemana,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
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

          // 🎯 Filtramos estrictamente las transacciones que pertenecen a esta semana
          final transaccionesSemana = todasTransacciones
              .where((t) => t.idSemana == idSemana)
              .toList();

          if (transaccionesSemana.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 50,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay movimientos en esta semana',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            itemCount: transaccionesSemana.length,
            itemBuilder: (context, index) {
              final t = transaccionesSemana[index];
              bool esIngreso = t.tipo == 'ingreso';

              IconData metodoIcon = Icons.payments_rounded;
              if (t.metodoPago == 'Nequi') {
                metodoIcon = Icons.phone_android_rounded;
              } else if (t.metodoPago == 'Tarjeta') {
                metodoIcon = Icons.credit_card_rounded;
              }

              final String fechaItem = DateFormat(
                'EEE, d MMM • h:mm a',
                'es',
              ).format(t.fecha);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (esIngreso ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      metodoIcon,
                      color: esIngreso
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    t.concepto,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '${t.pagadoPor} • ${t.metodoPago} • $fechaItem',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      '${esIngreso ? '+' : '-'}${currencyFormat.format(t.monto)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: esIngreso
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF87171),
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
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
