import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Modelo simple para contener los datos del reporte
class ReportData {
  final int totalAnimales;
  final int enGestacion;
  final int enLactancia;
  final int enSeca;
  final int partosUltimosMeses;
  final int saludables;
  final int enfermos;

  ReportData({
    this.totalAnimales = 0,
    this.enGestacion = 0,
    this.enLactancia = 0,
    this.enSeca = 0,
    this.partosUltimosMeses = 0,
    this.saludables = 0,
    this.enfermos = 0,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Future<ReportData>? _reportDataFuture;
  String? _animalTypeFilter;
  DateTimeRange? _dateRangeFilter;

  @override
  void initState() {
    super.initState();
    _reportDataFuture = _generateReportData();
  }

  void _applyFilters() {
    setState(() {
      _reportDataFuture = _generateReportData();
    });
  }

  // Función para obtener y procesar los datos de los animales
  Future<ReportData> _generateReportData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('animales');

    // Aplicar filtro de tipo de animal
    if (_animalTypeFilter != null) {
      query = query.where('tipo', isEqualTo: _animalTypeFilter);
    }

    // Aplicar filtro de rango de fechas (usando fecha de registro como ejemplo)
    if (_dateRangeFilter != null) {
      query = query
          .where('fechaRegistro', isGreaterThanOrEqualTo: _dateRangeFilter!.start)
          .where('fechaRegistro', isLessThanOrEqualTo: _dateRangeFilter!.end);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      return ReportData(); // Retorna data vacía si no hay animales
    }

    int enGestacion = 0;
    int enLactancia = 0;
    int enSeca = 0;
    int partosUltimosMeses = 0;
    int saludables = 0;
    int enfermos = 0;

    final twelveMonthsAgo = DateTime.now().subtract(const Duration(days: 365));

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Asumiendo que tienes un campo 'estadoReproductivo'
      switch (data['estadoReproductivo']) {
        case 'Gestación':
          enGestacion++;
          break;
        case 'Lactancia':
          enLactancia++;
          break;
        case 'Seca': // Asumiendo que 'Seca' es un estado posible
          enSeca++;
          break;
      }

      // Asumiendo un campo 'estadoSalud'
      if (data['estadoSalud'] == 'Saludable') {
        saludables++;
      } else if (data['estadoSalud'] == 'Enfermo') {
        enfermos++;
      }

      // Asumiendo un campo 'fechaParto' de tipo Timestamp
      if (data['fechaParto'] is Timestamp) {
        final fechaParto = (data['fechaParto'] as Timestamp).toDate();
        if (fechaParto.isAfter(twelveMonthsAgo)) {
          partosUltimosMeses++;
        }
      }
    }

    return ReportData(
      totalAnimales: snapshot.docs.length,
      enGestacion: enGestacion,
      enLactancia: enLactancia,
      enSeca: enSeca,
      partosUltimosMeses: partosUltimosMeses,
      saludables: saludables,
      enfermos: enfermos,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRangeFilter,
    );
    if (picked != null && picked != _dateRangeFilter) {
      setState(() {
        _dateRangeFilter = picked;
      });
      _applyFilters();
    }
  }

  void _showAnimalTypeFilter() {
    showModalBottomSheet(context: context, builder: (context) {
      return Wrap(
        children: <Widget>[
          ListTile(title: const Text('Todos los tipos'), onTap: () => _setAnimalTypeFilter(null)),
          ListTile(title: const Text('Vaca'), onTap: () => _setAnimalTypeFilter('Vaca')),
          ListTile(title: const Text('Cerda'), onTap: () => _setAnimalTypeFilter('Cerda')),
          ListTile(title: const Text('Cabra'), onTap: () => _setAnimalTypeFilter('Cabra')),
          ListTile(title: const Text('Oveja'), onTap: () => _setAnimalTypeFilter('Oveja')),
        ],
      );
    });
  }

  void _setAnimalTypeFilter(String? type) {
    setState(() {
      _animalTypeFilter = type;
    });
    Navigator.pop(context);
    _applyFilters();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Reportes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<ReportData>(
              future: _reportDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al generar el reporte: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.totalAnimales == 0) {
                  return const Center(child: Text('No hay animales que coincidan con los filtros.'));
                }

                final report = snapshot.data!;
                final totalSalud = report.saludables + report.enfermos;
                final saludGeneral = totalSalud > 0 ? (report.saludables / totalSalud) * 100 : 0;

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildReportCard(
                      title: 'Distribución por Etapa Reproductiva',
                      total: '${report.enGestacion + report.enLactancia + report.enSeca}',
                      totalLabel: 'Total',
                      metrics: {
                        'Gestación': report.enGestacion,
                        'Lactancia': report.enLactancia,
                        'Secas': report.enSeca,
                      },
                    ),
                    _buildReportCard(
                      title: 'Partos por Mes',
                      total: '${report.partosUltimosMeses}',
                      totalLabel: 'Últimos 12 meses',
                      metrics: {},
                    ),
                    _buildReportCard(
                      title: 'Salud General del Ganado',
                      total: '${saludGeneral.toStringAsFixed(0)}%',
                      totalLabel: 'Saludable',
                      metrics: {
                        'Saludables': report.saludables,
                        'Enfermos': report.enfermos,
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FilterChip(label: Text(_animalTypeFilter ?? 'Tipo de Animal'), onSelected: (_) => _showAnimalTypeFilter()),
          FilterChip(label: const Text('Rango de Fechas'), onSelected: (_) => _selectDateRange()),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String total,
    required String totalLabel,
    required Map<String, int> metrics,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(total, style: Theme.of(context).textTheme.headlineLarge),
            Text(totalLabel, style: Theme.of(context).textTheme.bodySmall),
            if (metrics.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: metrics.entries.map((entry) {
                  return Column(
                    children: [
                      Text(entry.value.toString(), style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  );
                }).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
