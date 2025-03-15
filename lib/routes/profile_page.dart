import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:baby_care_demo/models/grow_standard.dart';

class ProfilePage extends StatelessWidget {


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
              GrowStandard.girlWeight3MonthData.length,
                  (index) => _lineChartBarData(GrowStandard.girlWeight3MonthData[index], lineColors[index]),
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

