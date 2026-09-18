import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'graficas_screen.dart'; // 👈 NUEVO: Importamos la pantalla de gráficas

import '../providers/gasto_provider.dart';
import '../models/gasto_model.dart';
import 'historial_semanas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gastoProvider = Provider.of<GastoProvider>(context, listen: false);

    // 🎯 Obtenemos el usuario actual y definimos su nombre dinámicamente según el correo
    final user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? '';
    final String nombreUsuario = (email == 'alexgo.1496@gmail.com')
        ? 'Alexis'
        : 'Eimy';

    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits:
          0, // Sin decimales para ahorrar espacio visual y evitar desbordes
    );

    final String fechaHoyLarga = _obtenerFechaFormateada();

    final String semanaActualKey = GastoModel(
      concepto: '',
      monto: 0,
      categoria: '',
      pagadoPor: '',
      tipo: '',
      metodoPago: '',
      fecha: DateTime.now(),
    ).idSemana;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate Dark muy elegante
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.wallet,
                color: Color(0xFF60A5FA),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Control Finanzas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    nombreUsuario, // Muestra "Alexis" o "Eimy" completo y sin cortarse abajo
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          // NUEVO: Botón de Gráficas y Estadísticas en la barra superior
          IconButton(
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF60A5FA),
              size: 22,
            ),
            tooltip: 'Ver Gráficas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GraficasScreen()),
              );
            },
          ),

          // Botón Historial de Semanas
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            tooltip: 'Historial de Semanas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistorialSemanasScreen(),
                ),
              );
            },
          ),
          // Botón pequeño para Cerrar Sesión (Adaptado y seguro)
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFF87171),
                size: 18,
              ),
              tooltip: 'Cerrar Sesión',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              onPressed: () async {
                // 1. Cerramos la sesión en Firebase
                await FirebaseAuth.instance.signOut();

                // 2. Verificamos que el widget siga montado antes de navegar
                if (!context.mounted) return;

                // 3. Redirigimos al usuario a la pantalla de Login y borramos el historial
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ),
        ],
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
          final transacciones = todasTransacciones
              .where((t) => t.idSemana == semanaActualKey)
              .toList();

          double totalIngresos = transacciones
              .where((t) => t.tipo == 'ingreso')
              .fold(0, (sum, item) => sum + item.monto);

          double totalGastos = transacciones
              .where((t) => t.tipo == 'gasto')
              .fold(0, (sum, item) => sum + item.monto);

          double balanceNeto = totalIngresos - totalGastos;

          double ingresoNequi = transacciones
              .where((t) => t.tipo == 'ingreso' && t.metodoPago == 'Nequi')
              .fold(0, (sum, item) => sum + item.monto);

          double ingresoEfectivo = transacciones
              .where((t) => t.tipo == 'ingreso' && t.metodoPago == 'Efectivo')
              .fold(0, (sum, item) => sum + item.monto);

          double ingresoTarjetaSemanal = transacciones
              .where((t) => t.tipo == 'ingreso' && t.metodoPago == 'Tarjeta')
              .fold(0, (sum, item) => sum + item.monto);

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarjeta Principal de Balance
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
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
                                      fechaHoyLarga.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'SEMANAL',
                                      style: TextStyle(
                                        color: Color(0xFF60A5FA),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Balance Neto',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  currencyFormat.format(balanceNeto),
                                  style: TextStyle(
                                    color: balanceNeto >= 0
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFFF87171),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Divider(
                                color: Colors.white.withOpacity(0.06),
                                height: 1,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetodoCard(
                                      'Nequi',
                                      currencyFormat.format(ingresoNequi),
                                      Icons.phone_android_rounded,
                                      const Color(0xFF8B5CF6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetodoCard(
                                      'Efectivo',
                                      currencyFormat.format(ingresoEfectivo),
                                      Icons.payments_rounded,
                                      const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetodoCard(
                                      'Tarjeta',
                                      currencyFormat.format(
                                        ingresoTarjetaSemanal,
                                      ),
                                      Icons.credit_card_rounded,
                                      const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Movimientos Recientes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        transacciones.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      size: 40,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Sin movimientos esta semana',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: transacciones.length,
                                itemBuilder: (context, index) {
                                  final t = transacciones[index];
                                  bool esIngreso = t.tipo == 'ingreso';

                                  IconData metodoIcon = Icons.payments_rounded;
                                  if (t.metodoPago == 'Nequi') {
                                    metodoIcon = Icons.phone_android_rounded;
                                  } else if (t.metodoPago == 'Tarjeta') {
                                    metodoIcon = Icons.credit_card_rounded;
                                  }

                                  final String horaItem = DateFormat('h:mm a')
                                      .format(t.fecha);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B)
                                          .withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.04),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 4,
                                          ),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              (esIngreso
                                                      ? Colors.green
                                                      : Colors.red)
                                                  .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                        padding: const EdgeInsets.only(
                                          top: 2.0,
                                        ),
                                        child: Text(
                                          '${t.metodoPago} • $horaItem',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 95,
                                            ),
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
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Color(0xFF475569),
                                              size: 18,
                                            ),
                                            onPressed: () => gastoProvider
                                                .eliminarTransaccion(t.id!),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _mostrarModalAgregarTransaccion(context, nombreUsuario),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nuevo Registro',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 4,
      ),
    );
  }

  Widget _buildMetodoCard(
    String titulo,
    String monto,
    IconData icono,
    Color colorAccent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: colorAccent, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              monto,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerFechaFormateada() {
    final now = DateTime.now().toLocal();
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
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

    String diaSemana = dias[now.weekday - 1];
    String mes = meses[now.month - 1];

    return '$diaSemana, ${now.day} $mes';
  }

  void _mostrarModalAgregarTransaccion(
    BuildContext context,
    String nombreActual,
  ) {
    final conceptoController = TextEditingController();
    final montoController = TextEditingController();
    String tipoSeleccionado = 'ingreso';
    String metodoPagoSeleccionado = 'Nequi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nuevo Movimiento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: Text(
                                'Ingreso 📈',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            selected: tipoSeleccionado == 'ingreso',
                            selectedColor: const Color(0xFF059669),
                            backgroundColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: tipoSeleccionado == 'ingreso'
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                            onSelected: (selected) {
                              setStateModal(() => tipoSeleccionado = 'ingreso');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: Text(
                                'Gasto 📉',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            selected: tipoSeleccionado == 'gasto',
                            selectedColor: const Color(0xFFDC2626),
                            backgroundColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: tipoSeleccionado == 'gasto'
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                            onSelected: (selected) {
                              setStateModal(() => tipoSeleccionado = 'gasto');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: conceptoController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Concepto',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: montoController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: metodoPagoSeleccionado,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Método de Pago',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: ['Nequi', 'Efectivo', 'Tarjeta']
                          .map(
                            (metodo) => DropdownMenuItem(
                              value: metodo,
                              child: Text(metodo),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateModal(() => metodoPagoSeleccionado = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final concepto = conceptoController.text.trim();
                        final monto =
                            double.tryParse(montoController.text) ?? 0;

                        if (concepto.isNotEmpty && monto > 0) {
                          final nuevoGasto = GastoModel(
                            concepto: concepto,
                            monto: monto,
                            categoria: 'General',
                            pagadoPor: nombreActual,
                            tipo: tipoSeleccionado,
                            metodoPago: metodoPagoSeleccionado,
                            fecha: DateTime.now(),
                          );

                          Provider.of<GastoProvider>(
                            context,
                            listen: false,
                          ).agregarTransaccion(nuevoGasto);

                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Guardar Movimiento',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
