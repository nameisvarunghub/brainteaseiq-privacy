import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SpendSparkline extends StatelessWidget {
  final List<double> values;
  final Color line;
  final Color fillTop;
  final Color fillBottom;
  final double height;

  const SpendSparkline({
    super.key,
    required this.values,
    this.line = AppColors.brand,
    this.fillTop = const Color(0x66B084FF),
    this.fillBottom = const Color(0x00B084FF),
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);
    final maxV = (values.reduce((a, b) => a > b ? a : b)).clamp(1, double.infinity);
    final spots = <FlSpot>[
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxV * 1.15,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: line,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (s, _) => s.x == values.length - 1,
                getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeColor: line,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [fillTop, fillBottom],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }
}
