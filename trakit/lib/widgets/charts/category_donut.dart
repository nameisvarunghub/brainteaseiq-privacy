import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/formatters.dart';

class CategoryDonut extends StatefulWidget {
  final Map<String, double> byCategory;
  final double size;
  const CategoryDonut({super.key, required this.byCategory, this.size = 220});

  @override
  State<CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<CategoryDonut> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: widget.size * 0.32,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (e, res) {
                  setState(() {
                    if (!e.isInterestedForInteractions ||
                        res == null ||
                        res.touchedSection == null) {
                      _touched = -1;
                      return;
                    }
                    _touched = res.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: [
                for (int i = 0; i < entries.length; i++)
                  _section(entries[i], total, i),
              ],
            ),
            duration: const Duration(milliseconds: 700),
          ),
          IgnorePointer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _touched >= 0 && _touched < entries.length
                      ? entries[_touched].key
                      : 'This month',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _touched >= 0 && _touched < entries.length
                      ? Money.inr(entries[_touched].value)
                      : Money.inr(total),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section(MapEntry<String, double> e, double total, int i) {
    final pct = total == 0 ? 0 : (e.value / total) * 100;
    final isTouched = i == _touched;
    final gradient = AppGradients.category[e.key];
    return PieChartSectionData(
      value: e.value,
      title: pct >= 6 ? '${pct.toStringAsFixed(0)}%' : '',
      radius: isTouched ? widget.size * 0.30 : widget.size * 0.26,
      color: gradient?.colors.last ?? Theme.of(context).colorScheme.primary,
      gradient: gradient,
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.4,
      ),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: isTouched ? 0.4 : 0.12),
        width: isTouched ? 1.4 : 0.8,
      ),
    );
  }
}
