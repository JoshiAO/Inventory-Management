import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/discrepancy_service.dart';

class DashboardSummaryPage extends StatelessWidget {
  const DashboardSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _exportActualCountReport(context),
                icon: const Icon(Icons.download),
                label: const Text('Export Actual Count XLSX'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Total Items', '1,240', Icons.inventory, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Discrepancies', '14', Icons.warning, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Ongoing Counts', '5', Icons.pending_actions, Colors.purple)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildChartCard(
                    'Discrepancy by Category (PHP ₱)',
                    const _CategoryDiscrepancyChart(),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildChartCard(
                    'Count Status',
                    const _CountStatusPieChart(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportActualCountReport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Generating Actual Count XLSX...')),
    );

    try {
      final savedLocation = await DiscrepancyService().exportActualCountReport();
      messenger.showSnackBar(
        SnackBar(content: Text('Actual Count XLSX saved: $savedLocation')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $error'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(26),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            SizedBox(height: 300, child: chart),
          ],
        ),
      ),
    );
  }
}

class _CategoryDiscrepancyChart extends StatelessWidget {
  const _CategoryDiscrepancyChart();

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1000,
        barGroups: [
          _makeGroupData(0, 450),
          _makeGroupData(1, 800),
          _makeGroupData(2, 300),
          _makeGroupData(3, 150),
          _makeGroupData(4, 600),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['Drinks', 'Snacks', 'Fresh', 'Dry', 'Frozen'];
                return Text(titles[value.toInt()], style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: Colors.blue, width: 16)],
    );
  }
}

class _CountStatusPieChart extends StatelessWidget {
  const _CountStatusPieChart();

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(color: Colors.green, value: 65, title: '65%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12)),
          PieChartSectionData(color: Colors.orange, value: 20, title: '20%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12)),
          PieChartSectionData(color: Colors.red, value: 15, title: '15%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
