import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:baby_care_demo/models/grow_standard.dart';
import 'package:flutter_gen/gen_l10n/S.dart';

import '../widget/custom_tab_button.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<Color> lineColors = [Colors.blue, Colors.red, Colors.green];

  List<List<FlSpot>> selectedData = GrowStandard.girlWeight0to13WeekData;

  @override
  Widget build(BuildContext context) {
    double maxX=0.0, minX = 0.0, minY=0.0, maxY=0.0, intervalX=0.0, intervalY=0.0;

    if (selectedData == GrowStandard.girlWeight0to13WeekData||selectedData==GrowStandard.boyWeight0to13WeekData) {
      maxX = 13.0;
      minY = 2;
      maxY = 8.5;
      intervalX = 1;
      intervalY = 0.5;
    } else if (selectedData == GrowStandard.girlWeight0to6MonthData|| selectedData==GrowStandard.boyWeight0to6MonthData) {
      maxX = 60.0;
      minY = 2.0;
      maxY = 25.0;
      intervalX = 5;
      intervalY = 1.0;
    } else if (selectedData == GrowStandard.girlHeight0to13WeekData|| selectedData==GrowStandard.boyHeight0to13WeekData) {
      maxX = 13.0;
      minY = 45.0;
      maxY = 66.0;
      intervalX = 1;
      intervalY = 1.0;
    } else if(selectedData == GrowStandard.girlHeight0to24MonthData|| selectedData==GrowStandard.boyHeight0to24MonthData){
      maxX = 24.0;
      minY = 45.0;
      maxY = 94.0;
      intervalX = 1;
      intervalY = 1.0;
    }else if (selectedData == GrowStandard.girlBMI0to13WeekData|| selectedData==GrowStandard.boyBMI0to13WeekData) {
      maxX = 13.0;
      minY = 11.0;
      maxY = 20.0;
      intervalX = 1;
      intervalY = 1.0;
    } else if(selectedData == GrowStandard.girlBMI0to24MonthData|| selectedData==GrowStandard.boyBMI0to24MonthData){
      maxX = 24.0;
      minY = 11.0;
      maxY = 20.0;
      intervalX = 1;
      intervalY = 1.0;
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 100,
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomTabButton(
                  label: S.of(context)?.formula ?? "formula",
                  iconPath: 'assets/icons/formula_milk.png',
                  onTap: () {
                    setState(() {
                      selectedData = GrowStandard.girlWeight0to13WeekData;
                    });
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.water ?? "water",
                  iconPath: 'assets/icons/water.png',
                  onTap: () {
                    setState(() {
                      selectedData = GrowStandard.girlHeight0to13WeekData;
                    });
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.poop ?? "poop",
                  iconPath: 'assets/icons/poop.png',
                  onTap: () {
                    setState(() {
                      selectedData = GrowStandard.girlBMI0to13WeekData;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 2.0),
                            child: Text(value.toStringAsFixed(1)),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: intervalX,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 0.0),
                            child: Text(value.toInt().toString()),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: intervalY,
                    verticalInterval: intervalX,
                  ),
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: List.generate(
                    selectedData.length,
                    (index) => _lineChartBarData(
                      selectedData[index],
                      lineColors[index % lineColors.length],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(show: false),
      dotData: FlDotData(show: false),
    );
  }
}
