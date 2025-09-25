import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class SupplierChart extends StatelessWidget {
  final Map<String, double> data;

  const SupplierChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = data.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList();

    if (chartData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SfCircularChart(
          title: ChartTitle(
            text: 'Dépenses par Fournisseur',
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
          legend: Legend(
            isVisible: true,
            position: LegendPosition.bottom,
            overflowMode: LegendItemOverflowMode.wrap,
          ),
          series: <PieSeries<ChartData, String>>[
            PieSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.label,
              yValueMapper: (ChartData data, _) => data.value,
              dataLabelMapper: (ChartData data, _) =>
                  '${data.label}\n${NumberFormat('#,##0', 'fr_FR').format(data.value)} FCFA',
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                labelPosition: ChartDataLabelPosition.outside,
                textStyle: TextStyle(fontSize: 10),
              ),
              explode: true,
              explodeIndex: 0,
              enableTooltip: true,
            ),
          ],
          tooltipBehavior: TooltipBehavior(
            enable: true,
            format: 'point.x: point.y FCFA',
          ),
        ),
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}