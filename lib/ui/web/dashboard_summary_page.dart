import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/discrepancy_service.dart';
import '../../providers/dashboard_provider.dart';

class DashboardSummaryPage extends StatelessWidget {
  const DashboardSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final dashboardProvider = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Inventory Overview'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: ElevatedButton.icon(
              onPressed: () => _exportActualCountReport(context),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('EXPORT REPORT (XLSX)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      body: dashboardProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard('Total Items', dashboardProvider.totalItems.toString(), Icons.inventory_2_outlined, primaryColor)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildSummaryCard('Discrepancies', dashboardProvider.discrepanciesCount.toString(), Icons.warning_amber_rounded, AppTheme.warningColor)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildSummaryCard('Active Counts', dashboardProvider.activeCounts.toString(), Icons.timer_outlined, Colors.deepPurple)),
                    ],
                  ),
                  const SizedBox(height: 40),
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
                          'Count Completion Status',
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
      const SnackBar(
        content: Text('Generating Actual Count XLSX...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final savedLocation = await DiscrepancyService().exportActualCountReport();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Actual Count XLSX saved: $savedLocation'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $error'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(height: 320, child: chart),
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
