import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfilePage extends StatelessWidget {
  // 3 条体重对年龄的曲线数据（0~13周）
  final List<List<FlSpot>> weightData = [
    [
      // 第一条曲线（示例：正常增长曲线）
      FlSpot(0, 3.0), FlSpot(1, 3.2), FlSpot(2, 3.5), FlSpot(3, 3.8),
      FlSpot(4, 4.1), FlSpot(5, 4.4), FlSpot(6, 4.7), FlSpot(7, 5.0),
      FlSpot(8, 5.3), FlSpot(9, 5.6), FlSpot(10, 6.0), FlSpot(11, 6.3),
      FlSpot(12, 6.5), FlSpot(13, 6.8),
    ],
    [
      // 第二条曲线（示例：较慢增长曲线）
      FlSpot(0, 2.8), FlSpot(1, 3.0), FlSpot(2, 3.2), FlSpot(3, 3.4),
      FlSpot(4, 3.7), FlSpot(5, 4.0), FlSpot(6, 4.2), FlSpot(7, 4.5),
      FlSpot(8, 4.7), FlSpot(9, 5.0), FlSpot(10, 5.2), FlSpot(11, 5.5),
      FlSpot(12, 5.7), FlSpot(13, 6.0),
    ],
    [
      // 第三条曲线（示例：快速增长曲线）
      FlSpot(0, 3.2), FlSpot(1, 3.5), FlSpot(2, 3.9), FlSpot(3, 4.3),
      FlSpot(4, 4.7), FlSpot(5, 5.1), FlSpot(6, 5.5), FlSpot(7, 6.0),
      FlSpot(8, 6.4), FlSpot(9, 6.8), FlSpot(10, 7.1), FlSpot(11, 7.5),
      FlSpot(12, 7.8), FlSpot(13, 8.0),
    ],
  ];

  final List<Color> lineColors = [Colors.blue, Colors.red, Colors.green];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('体重对年龄曲线')),
      body: Padding(
        padding: const EdgeInsets.all(56.0),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(enabled: false), // 禁用点击事件
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                axisNameWidget: Text("体重 (kg)"), // Y 轴标题
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toStringAsFixed(1));
                  },
                ),
              ),
              rightTitles: AxisTitles( // **隐藏右侧 Y 轴刻度**
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles( // **隐藏顶部 X 轴刻度**
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: Text("年龄 (周)"), // X 轴标题
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 1, // **保证 X 轴 13 格**
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString()); // **显示整数年龄（周）**
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true, // 显示垂直网格线
              horizontalInterval: 0.5, // Y 轴网格间隔
              verticalInterval: 1, // X 轴网格间隔，确保 X 轴有 13 格
            ),
            minX: 0, // X 轴最小值（0 周）
            maxX: 13, // X 轴最大值（13 周）
            minY: 2.5, // 体重最小值（略低于数据最小值）
            maxY: 8.5, // 体重最大值（略高于数据最大值）
            lineBarsData: List.generate(
              weightData.length,
                  (index) => _lineChartBarData(weightData[index], lineColors[index]),
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true, // 让曲线平滑
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(show: false), // 不显示曲线下方填充区域
      dotData: FlDotData(show: false), // **隐藏数据点**
    );
  }
}

