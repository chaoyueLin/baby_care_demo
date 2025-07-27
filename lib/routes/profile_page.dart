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
  static const String TYPE_WEIGHT = 'weight';
  static const String TYPE_HEIGHT = 'height';
  static const String TYPE_BMI = 'bmi';
  static const String RANGE_13W = '0-13w';
  static const String RANGE_12M = '0-12m';
  static const String RANGE_24M = '12-24m';

  String selectedType = TYPE_WEIGHT;
  String selectedRange = RANGE_13W;
  List<List<FlSpot>> selectedData = [];

  @override
  void initState() {
    super.initState();
    updateSelectedData();
  }

  void updateSelectedData() {
    if (selectedType == TYPE_WEIGHT) {
      if (selectedRange == RANGE_13W) {
        selectedData = GrowStandard.girlWeight0to13WeekData;
      } else if (selectedRange == RANGE_12M) {
        selectedData = GrowStandard.girlWeight0to12MonthData;
      } else {
        selectedData = GrowStandard.girlWeight12to24MonthData;
      }
    } else if (selectedType == TYPE_HEIGHT) {
      if (selectedRange == RANGE_13W) {
        selectedData = GrowStandard.girlHeight0to13WeekData;
      } else if (selectedRange == RANGE_12M) {
        selectedData = GrowStandard.girlHeight0to12MonthData;
      } else {
        selectedData = GrowStandard.girlHeight12to24MonthData;
      }
    } else if (selectedType == TYPE_BMI) {
      if (selectedRange == RANGE_13W) {
        selectedData = GrowStandard.girlBMI0to13WeekData;
      } else if (selectedRange == RANGE_12M) {
        selectedData = GrowStandard.girlBMI0to12MonthData;
      } else {
        selectedData = GrowStandard.girlBMI12to24MonthData;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double maxX = 0.0,
        minX = 0.0,
        minY = 0.0,
        maxY = 0.0,
        intervalX = 0.0,
        intervalY = 0.0;

    updateSelectedData();

    if (selectedType == TYPE_WEIGHT) {
      if (selectedRange == RANGE_13W) {
        maxX = 13.0;
        minY = 2;
        maxY = 8.5;
      } else if (selectedRange == RANGE_12M) {
        maxX = 12.0;
        minY = 2.0;
        maxY = 12.0;
      } else {
        minX = 12.0;
        maxX = 24.0;
        minY = 7.0;
        maxY = 16.0;
      }
    } else if (selectedType == TYPE_HEIGHT) {
      if (selectedRange == RANGE_13W) {
        maxX = 13.0;
        minY = 45.0;
        maxY = 66.0;
      } else if (selectedRange == RANGE_12M) {
        maxX = 12.0;
        minY = 46.0;
        maxY = 81.0;
      } else {
        minX = 12.0;
        maxX = 24.0;
        minY = 68.0;
        maxY = 94.0;
      }
    } else if (selectedType == TYPE_BMI) {
      if (selectedRange == RANGE_13W) {
        maxX = 13.0;
        minY = 10.0;
        maxY = 20.0;
      } else if (selectedRange == RANGE_12M) {
        maxX = 12.0;
        minY = 11.0;
        maxY = 20.5;
      } else {
        minX = 12.0;
        maxX = 24.0;
        minY = 13.0;
        maxY = 20;
      }
    }

    intervalX = 1;
    intervalY = 1;

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
                      selectedType = TYPE_WEIGHT;
                      updateSelectedData();
                    });
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.water?? "water",
                  iconPath: 'assets/icons/water.png',
                  onTap: () {
                    setState(() {
                      selectedType = TYPE_HEIGHT;
                      updateSelectedData();
                    });
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.poop??"poop",
                  iconPath: 'assets/icons/poop.png',
                  onTap: () {
                    setState(() {
                      selectedType = TYPE_BMI;
                      updateSelectedData();
                    });
                  },
                ),
              ],
            ),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: RANGE_13W,
                  groupValue: selectedRange,
                  onChanged: (value) {
                    setState(() {
                      selectedRange = value!;
                      updateSelectedData();
                    });
                  },
                ),
                const Text('0-13周'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: RANGE_12M,
                  groupValue: selectedRange,
                  onChanged: (value) {
                    setState(() {
                      selectedRange = value!;
                      updateSelectedData();
                    });
                  },
                ),
                const Text('0-12个月'),
                Radio<String>(
                  value: RANGE_24M,
                  groupValue: selectedRange,
                  onChanged: (value) {
                    setState(() {
                      selectedRange = value!;
                      updateSelectedData();
                    });
                  },
                ),
                const Text('12-24个月'),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
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
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
