import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfilePage extends StatelessWidget {
  final List<double> heightData = [45, 50, 55, 60, 65, 70, 75, 80, 85, 90,90,90];
  final List<double> weightData = [2, 3, 4, 4.5, 5, 5.5,6,7,7.5,8];
  final List<int> months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,11,12];

  // 身高数据映射：45-90 -> 30-100（确保身高起点距离 X 轴 30dp）
  List<FlSpot> getHeightSpots() {
    const double minHeight = 45;
    const double maxHeight = 90;
    const double yStart = 60; // 60dp 偏移量
    const double yRange = 100 - yStart;

    return heightData.asMap().entries.map((entry) {
      final double x = months[entry.key].toDouble();
      final double y = yStart + ((entry.value - minHeight) / (maxHeight - minHeight)) * yRange;
      return FlSpot(x, y);
    }).toList();
  }

  // 体重数据映射：0-15 -> 0-100
  List<FlSpot> getWeightSpots() {
    const double maxWeight = 15;
    return weightData.asMap().entries.map((entry) {
      final double x = months[entry.key].toDouble();
      final double y = (entry.value / maxWeight) * 100;
      return FlSpot(x, y);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(26.0),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(enabled: false),
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Color(0xff72719b),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    // 反向映射：Y轴显示实际身高（45-90）
                    const double minHeight = 45;
                    const double maxHeight = 90;
                    const double yStart = 60;
                    const double yRange = 100 - yStart;
                    final double actualHeight =
                        minHeight + ((value - yStart) / yRange) * (maxHeight - minHeight);
                    return Text(
                      actualHeight.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Color(0xff75729e),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    // 反向映射：Y轴显示实际体重（0-15）
                    const double maxWeight = 15;
                    final double actualWeight = (value / 100) * maxWeight;
                    return Text(
                      actualWeight.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xff75729e),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: 1,
            maxX: 12,
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: getHeightSpots(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 4,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              LineChartBarData(
                spots: getWeightSpots(),
                isCurved: true,
                color: Colors.red,
                barWidth: 4,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
