import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:baby_care_demo/models/grow_standard.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

import '../common/db_provider.dart';
import '../models/baby.dart';
import '../models/baby_grow.dart';
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

  Baby? currentBaby ;
  // 用于输入弹窗的控制器
  final TextEditingController _valueController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCurrentBabyAndData();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  /// 获取当前 babyId 并加载数据
  Future<void> _loadCurrentBabyAndData() async {
    List<Baby>? visibleBabies = await DBProvider().getVisiblePersons();
    if (visibleBabies != null && visibleBabies.isNotEmpty) {
      Baby? baby = visibleBabies.firstWhere(
            (b) => b.show == 1,
        orElse: () => visibleBabies.first,
      );
      currentBaby=baby;

      updateSelectedData();
    }
  }

  bool isBoy() {
    return currentBaby?.sex == 1;
  }

  void updateSelectedData() {
    if (selectedType == TYPE_WEIGHT) {
      if (selectedRange == RANGE_13W) {
        if (isBoy()) {
          selectedData = GrowStandard.boyWeight0to13WeekData;
        } else {
          selectedData = GrowStandard.girlWeight0to13WeekData;
        }
      } else if (selectedRange == RANGE_12M) {
        if (isBoy()) {
          selectedData = GrowStandard.boyWeight0to12MonthData;
        } else {
          selectedData = GrowStandard.girlWeight0to12MonthData;
        }
      } else {
        if (isBoy()) {
          selectedData = GrowStandard.boyWeight12to24MonthData;
        } else {
          selectedData = GrowStandard.girlWeight12to24MonthData;
        }
      }
    } else if (selectedType == TYPE_HEIGHT) {
      if (selectedRange == RANGE_13W) {
        if (isBoy()) {
          selectedData = GrowStandard.boyHeight0to13WeekData;
        } else {
          selectedData = GrowStandard.girlHeight0to13WeekData;
        }
      } else if (selectedRange == RANGE_12M) {
        if (isBoy()) {
          selectedData = GrowStandard.boyHeight0to12MonthData;
        } else {
          selectedData = GrowStandard.girlHeight0to12MonthData;
        }
      } else {
        if (isBoy()) {
          selectedData = GrowStandard.boyHeight12to24MonthData;
        } else {
          selectedData = GrowStandard.girlHeight12to24MonthData;
        }
      }
    } else if (selectedType == TYPE_BMI) {
      if (selectedRange == RANGE_13W) {
        if (isBoy()) {
          selectedData = GrowStandard.boyBMI0to13WeekData;
        } else {
          selectedData = GrowStandard.girlBMI0to13WeekData;
        }
      } else if (selectedRange == RANGE_12M) {
        if (isBoy()) {
          selectedData = GrowStandard.boyBMI0to12MonthData;
        } else {
          selectedData = GrowStandard.girlBMI0to12MonthData;
        }
      } else {
        if (isBoy()) {
          selectedData = GrowStandard.boyBMI12to24MonthData;
        } else {
          selectedData = GrowStandard.girlBMI12to24MonthData;
        }
      }
    }
  }

  /// 显示添加数据弹窗
  void _showAddDataDialog() {
    _valueController.clear();
    _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_getDialogTitle()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 数值输入框
                  TextField(
                    controller: _valueController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _getInputLabel(),
                      hintText: _getInputHint(),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // 日期选择
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showDatePicker(setDialogState);
                      },
                      child: Text(
                        '选择日期: ${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    _saveGrowData();
                    Navigator.of(context).pop();
                  },
                  child: Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示日期选择器
  void _showDatePicker(StateSetter setDialogState) {
    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: currentBaby?.birthdate,
      maxTime: DateTime.now(),
      currentTime: _selectedDate,
      onConfirm: (date) {
        setDialogState(() {
          _selectedDate = date;
        });
      },
      locale: LocaleType.zh, // 设置为中文
    );
  }

  /// 保存成长数据
  Future<void> _saveGrowData() async {
    if ( _valueController.text.trim().isEmpty) {
      return;
    }

    double? value = double.tryParse(_valueController.text.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入有效的数值')),
      );
      return;
    }

    GrowType growType;
    if (selectedType == TYPE_WEIGHT) {
      growType = GrowType.weight;
    } else if (selectedType == TYPE_HEIGHT) {
      growType = GrowType.height;
    } else {
      // BMI 类型暂时不支持直接输入，可能需要通过身高体重计算
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BMI 数据需要通过身高和体重计算获得')),
      );
      return;
    }

    BabyGrow growData = BabyGrow(
      babyId: currentBaby?.id??0,
      date: _selectedDate.millisecondsSinceEpoch,
      type: growType,
      mush: value.toString(),
    );

    try {
      await DBProvider().insertGrow(growData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据保存成功')),
      );
      // 可以在这里刷新图表数据
      setState(() {
        updateSelectedData();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  /// 获取弹窗标题
  String _getDialogTitle() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return '添加体重数据';
      case TYPE_HEIGHT:
        return '添加身高数据';
      case TYPE_BMI:
        return '添加BMI数据';
      default:
        return '添加数据';
    }
  }

  /// 获取输入框标签
  String _getInputLabel() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return '体重';
      case TYPE_HEIGHT:
        return '身高';
      case TYPE_BMI:
        return 'BMI';
      default:
        return '数值';
    }
  }

  /// 获取输入框提示
  String _getInputHint() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return '请输入体重 (kg)';
      case TYPE_HEIGHT:
        return '请输入身高 (cm)';
      case TYPE_BMI:
        return '请输入BMI';
      default:
        return '请输入数值';
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
                  label: S.of(context)?.water ?? "water",
                  iconPath: 'assets/icons/water.png',
                  onTap: () {
                    setState(() {
                      selectedType = TYPE_HEIGHT;
                      updateSelectedData();
                    });
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.poop ?? "poop",
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
              children: [
                // 左侧：时间范围选择器
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                      const SizedBox(width: 8),
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
                      const SizedBox(width: 8),
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
                // 右侧：添加数据按钮（BMI类型时隐藏）
                if (selectedType != TYPE_BMI)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      onPressed: _showAddDataDialog,
                      padding: EdgeInsets.zero,
                    ),
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