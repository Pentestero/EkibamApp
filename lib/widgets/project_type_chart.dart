import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class ProjectTypeChart extends StatelessWidget {
  final Map<String, double> data;

  const ProjectTypeChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = data.entries
        .map((entry) => ProjectTypeData(entry.key, entry.value))
        .toList();

    if (chartData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SfCartesianChart(
          title: ChartTitle(
            text: 'Dépenses par Type de Projet',
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
          primaryXAxis: CategoryAxis(
            labelStyle: const TextStyle(fontSize: 10),
          ),
          primaryYAxis: NumericAxis(
            labelFormat: '{value}',
            numberFormat: NumberFormat('#,##0', 'fr_FR'),
          ),
          series: <ColumnSeries<ProjectTypeData, String>>[
            ColumnSeries<ProjectTypeData, String>(
              dataSource: chartData,
              xValueMapper: (ProjectTypeData data, _) => data.projectType,
              yValueMapper: (ProjectTypeData data, _) => data.amount,
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment.top,
                textStyle: TextStyle(fontSize: 10),
              ),
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
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

class ProjectTypeData {
  final String projectType;
  final double amount;

  ProjectTypeData(this.projectType, this.amount);
}