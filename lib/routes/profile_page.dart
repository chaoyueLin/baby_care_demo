import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) {
                    return Text('${value.toInt()} cm',
                        style: TextStyle(fontSize: 12));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text('${value.toInt()}',
                        style: TextStyle(fontSize: 12));
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            minX: 0,
            maxX: 30,  // 30个数据点
            minY: 40,  // 假设身高的最小值是40
            maxY: 80,  // 假设身高的最大值是80
            lineBarsData: [
              LineChartBarData(
                spots: _generateHeightData(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),
              ),
              LineChartBarData(
                spots: _generateWeightData(),
                isCurved: true,
                color: Colors.green,
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 模拟身高数据（30个数据点）
  List<FlSpot> _generateHeightData() {
    return [
      FlSpot(0, 50), FlSpot(1, 52), FlSpot(2, 53), FlSpot(3, 54), FlSpot(4, 55),
      FlSpot(5, 56), FlSpot(6, 57), FlSpot(7, 58), FlSpot(8, 59), FlSpot(9, 60),
      FlSpot(10, 61), FlSpot(11, 62), FlSpot(12, 63), FlSpot(13, 64), FlSpot(14, 65),
      FlSpot(15, 66), FlSpot(16, 67), FlSpot(17, 68), FlSpot(18, 69), FlSpot(19, 70),
      FlSpot(20, 71), FlSpot(21, 72), FlSpot(22, 73), FlSpot(23, 74), FlSpot(24, 75),
      FlSpot(25, 76), FlSpot(26, 77), FlSpot(27, 78), FlSpot(28, 79), FlSpot(29, 80),
    ];
  }

  // 模拟体重数据（30个数据点）
  List<FlSpot> _generateWeightData() {
    return [
      FlSpot(0, 3.5), FlSpot(1, 3.6), FlSpot(2, 3.7), FlSpot(3, 3.8), FlSpot(4, 4.0),
      FlSpot(5, 4.2), FlSpot(6, 4.3), FlSpot(7, 4.5), FlSpot(8, 4.7), FlSpot(9, 4.9),
      FlSpot(10, 5.1), FlSpot(11, 5.3), FlSpot(12, 5.5), FlSpot(13, 5.7), FlSpot(14, 5.9),
      FlSpot(15, 6.1), FlSpot(16, 6.3), FlSpot(17, 6.5), FlSpot(18, 6.7), FlSpot(19, 6.9),
      FlSpot(20, 7.1), FlSpot(21, 7.3), FlSpot(22, 7.5), FlSpot(23, 7.7), FlSpot(24, 7.9),
      FlSpot(25, 8.1), FlSpot(26, 8.3), FlSpot(27, 8.5), FlSpot(28, 8.7), FlSpot(29, 8.9),
    ];
  }
}
