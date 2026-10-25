import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';
import '../utils/formatters.dart';

class CategoryPieData {
  final Category category;
  final double amount;
  final double percentage;

  const CategoryPieData({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class CategoryDonutChart extends StatefulWidget {
  final List<CategoryPieData> data;
  final String currencySymbol;
  final double totalAmount;

  const CategoryDonutChart({
    super.key,
    required this.data,
    required this.currencySymbol,
    required this.totalAmount,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No transaction data for this period')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 65,
                  sections: widget.data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isTouched = index == _touchedIndex;
                    final radius = isTouched ? 32.0 : 25.0;

                    return PieChartSectionData(
                      color: Color(item.category.colorValue),
                      value: item.amount,
                      title: '',
                      radius: radius,
                    );
                  }).toList(),
                ),
              ),

              // Center Summary
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _touchedIndex >= 0 && _touchedIndex < widget.data.length
                        ? widget.data[_touchedIndex].category.name
                        : 'Total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatCompactNumber(
                      _touchedIndex >= 0 && _touchedIndex < widget.data.length
                          ? widget.data[_touchedIndex].amount
                          : widget.totalAmount,
                      currencySymbol: widget.currencySymbol,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  if (_touchedIndex >= 0 && _touchedIndex < widget.data.length)
                    Text(
                      '${widget.data[_touchedIndex].percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Color(widget.data[_touchedIndex].category.colorValue),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Legend / Top categories list
        ...widget.data.take(5).map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(item.category.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.category.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppFormatters.formatCurrency(item.amount, currencySymbol: widget.currencySymbol),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class TrendBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String currencySymbol;
  final Color barColor;

  const TrendBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.currencySymbol,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (values.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No trend data available')),
      );
    }

    double maxY = 0;
    for (final v in values) {
      if (v > maxY) maxY = v;
    }
    if (maxY == 0) maxY = 100;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${labels[group.x.toInt()]}\n${AppFormatters.formatCurrency(rod.toY, currencySymbol: currencySymbol)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final index = val.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (val) {
              return FlLine(
                color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.1 : 0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: values.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: barColor,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.15,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.2 : 0.3),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CumulativeLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final String currencySymbol;
  final Color lineColor;

  const CumulativeLineChart({
    super.key,
    required this.spots,
    required this.currencySymbol,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (spots.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No spending activity yet')),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.1 : 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(
            show: false,
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
