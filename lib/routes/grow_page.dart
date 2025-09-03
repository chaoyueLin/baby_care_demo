import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:baby_care_demo/models/grow_standard.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

import '../common/db_provider.dart';
import '../models/baby.dart';
import '../models/baby_grow.dart';
import '../widget/custom_tab_button.dart';

class GrowPage extends StatefulWidget {
  const GrowPage({super.key});

  @override
  State<GrowPage> createState() => _GrowPageState();
}

class _GrowPageState extends State<GrowPage> {
  static const String TYPE_WEIGHT = 'weight';
  static const String TYPE_HEIGHT = 'height';
  static const String TYPE_BMI = 'bmi';

  static const String RANGE_13W = '0-13w';
  static const String RANGE_12M = '0-12m';
  static const String RANGE_24M = '12-24m';

  String selectedType = TYPE_WEIGHT;
  String selectedRange = RANGE_13W;

  List<List<FlSpot>> selectedData = [];
  List<FlSpot> babySeries = [];

  Baby? currentBaby;

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

  Future<void> _loadCurrentBabyAndData() async {
    try {
      final visibleBabies = await DBProvider().getVisiblePersons();
      if (visibleBabies != null && visibleBabies.isNotEmpty) {
        final baby = visibleBabies.firstWhere(
              (b) => b.show == 1,
          orElse: () => visibleBabies.first,
        );
        setState(() => currentBaby = baby);
      }
    } catch (_) {}
    await _refreshAll();
  }

  bool isBoy() => (currentBaby?.sex ?? 1) == 1;

  Future<void> _refreshAll() async {
    _updateSelectedData();
    await _loadBabySeries();
    if (mounted) setState(() {});
  }

  void _updateSelectedData() {
    if (selectedType == TYPE_WEIGHT) {
      if (selectedRange == RANGE_13W) {
        selectedData = isBoy()
            ? GrowStandard.boyWeight0to13WeekData
            : GrowStandard.girlWeight0to13WeekData;
      } else if (selectedRange == RANGE_12M) {
        selectedData = isBoy()
            ? GrowStandard.boyWeight0to12MonthData
            : GrowStandard.girlWeight0to12MonthData;
      } else {
        selectedData = isBoy()
            ? GrowStandard.boyWeight12to24MonthData
            : GrowStandard.girlWeight12to24MonthData;
      }
    } else if (selectedType == TYPE_HEIGHT) {
      if (selectedRange == RANGE_13W) {
        selectedData = isBoy()
            ? GrowStandard.boyHeight0to13WeekData
            : GrowStandard.girlHeight0to13WeekData;
      } else if (selectedRange == RANGE_12M) {
        selectedData = isBoy()
            ? GrowStandard.boyHeight0to12MonthData
            : GrowStandard.girlHeight0to12MonthData;
      } else {
        selectedData = isBoy()
            ? GrowStandard.boyHeight12to24MonthData
            : GrowStandard.girlHeight12to24MonthData;
      }
    } else if (selectedType == TYPE_BMI) {
      if (selectedRange == RANGE_13W) {
        selectedData = isBoy()
            ? GrowStandard.boyBMI0to13WeekData
            : GrowStandard.girlBMI0to13WeekData;
      } else if (selectedRange == RANGE_12M) {
        selectedData = isBoy()
            ? GrowStandard.boyBMI0to12MonthData
            : GrowStandard.girlBMI0to12MonthData;
      } else {
        selectedData = isBoy()
            ? GrowStandard.boyBMI12to24MonthData
            : GrowStandard.girlBMI12to24MonthData;
      }
    }
  }

  double _calcXByBirth(DateTime birth, DateTime when) {
    final diffDays = when.difference(birth).inDays.toDouble();
    if (selectedRange == RANGE_13W) {
      return diffDays / 7.0;
    } else {
      return diffDays / 30.4375;
    }
  }

  Future<void> _loadBabySeries() async {
    babySeries = [];
    if (currentBaby == null) return;

    final birth = currentBaby!.birthdate ?? DateTime.fromMillisecondsSinceEpoch(0);

    DateTime start, end;
    if (selectedRange == RANGE_13W) {
      start = birth;
      end = birth.add(const Duration(days: 13 * 7));
    } else if (selectedRange == RANGE_12M) {
      start = birth;
      end = birth.add(const Duration(days: 365));
    } else {
      start = birth.add(const Duration(days: 365));
      end = birth.add(const Duration(days: (365 * 2)));
    }

    final type = _toGrowType(selectedType);
    if (type == null) return;

    try {
      final List<BabyGrow> list = await DBProvider().getBabyGrows(
        babyId: currentBaby!.id ?? 0,
        type: type,
        startMs: start.millisecondsSinceEpoch,
        endMs: end.millisecondsSinceEpoch,
      );

      final spots = <FlSpot>[];
      for (final g in list) {
        final t = DateTime.fromMillisecondsSinceEpoch(g.date ?? 0);
        final x = _calcXByBirth(birth, t);
        final xAdj = (selectedRange == RANGE_24M) ? x.clamp(12.0, 24.0) : x;
        final y = double.tryParse(g.mush ?? '') ?? 0.0;
        if (y > 0) spots.add(FlSpot(xAdj, y));
      }

      spots.sort((a, b) => a.x.compareTo(b.x));
      babySeries = spots;
    } catch (e) {
      debugPrint('load baby series error: $e');
      babySeries = [];
    }
  }

  GrowType? _toGrowType(String t) {
    switch (t) {
      case TYPE_WEIGHT:
        return GrowType.weight;
      case TYPE_HEIGHT:
        return GrowType.height;
      default:
        return null;
    }
  }

  void _showAddDataDialog() {
    _valueController.clear();
    _selectedDate = DateTime.now();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              titleTextStyle: tt.titleMedium?.copyWith(color: Colors.white),
              contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onSurface),
              backgroundColor: cs.surface,
              title: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    topRight: Radius.circular(12.0),
                  ),
                ),
                child:  Text(
                  _getDialogTitle() ?? '',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              titlePadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _getInputLabel() ?? '',
                      hintText: _getInputHint() ?? '',
                      border: const OutlineInputBorder(),
                    ),
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showDatePicker(setDialogState),
                      child: Text(
                        '${S.of(context)?.chooseDate ?? '选择日期'}: ${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(S.of(context)?.cancel ?? '取消', style: tt.labelLarge?.copyWith(color: cs.primary)),
                ),
                TextButton(
                  onPressed: () async {
                    await _saveGrowData();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(S.of(context)?.save ?? '保存', style: tt.labelLarge?.copyWith(color: cs.primary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDatePicker(StateSetter setDialogState) {
    final min = currentBaby?.birthdate ?? DateTime(2000, 1, 1);
    final max = DateTime.now();

    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: min.isAfter(max) ? max : min,
      maxTime: max,
      currentTime: _selectedDate,
      onConfirm: (date) => setDialogState(() => _selectedDate = date),
      locale: LocaleType.zh,
    );
  }

  Future<void> _saveGrowData() async {
    if (_valueController.text.trim().isEmpty) return;
    if (currentBaby == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)?.pleaseAddOrSelectBaby ?? '请先添加或选择一个宝宝')),
      );
      return;
    }

    final value = double.tryParse(_valueController.text.trim());
    if (value == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)?.pleaseEnterValidNumber ?? '请输入有效的数值')),
      );
      return;
    }

    final growType = _toGrowType(selectedType);
    if (growType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)?.bmiNeedHeightWeight ?? 'BMI 数据需要通过身高和体重计算获得')),
      );
      return;
    }

    final growData = BabyGrow(
      babyId: currentBaby!.id ?? 0,
      date: _selectedDate.millisecondsSinceEpoch,
      type: growType,
      mush: value.toString(),
    );

    try {
      await DBProvider().insertGrow(growData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据保存成功')),
      );
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  String? _getDialogTitle() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return S.of(context)?.addWeight ?? '添加体重数据';
      case TYPE_HEIGHT:
        return S.of(context)?.addHeight ?? '添加身高数据';
      case TYPE_BMI:
        return S.of(context)?.addBMI ?? '添加BMI数据';
      default:
        return S.of(context)?.addData ?? '添加数据';
    }
  }

  String? _getInputLabel() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return S.of(context)?.weight ?? '体重';
      case TYPE_HEIGHT:
        return S.of(context)?.height ?? '身高';
      case TYPE_BMI:
        return S.of(context)?.bmi ?? 'BMI';
      default:
        return S.of(context)?.value ?? '数值';
    }
  }

  String? _getInputHint() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return S.of(context)?.enterWeightKg ?? '请输入体重 (kg)';
      case TYPE_HEIGHT:
        return S.of(context)?.enterHeightCm ?? '请输入身高 (cm)';
      case TYPE_BMI:
        return S.of(context)?.enterBMI ?? '请输入BMI';
      default:
        return S.of(context)?.enterValue ?? '请输入数值';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final tertiary = cs.tertiary ?? cs.secondary;
    final lineColors = [Colors.lightGreen.shade200, Colors.lightGreen.shade300, Colors.lightGreen.shade400];

    double maxX = 0, minX = 0, minY = 0, maxY = 0;
    if (selectedType == TYPE_WEIGHT) {
      if (selectedRange == RANGE_13W) {
        maxX = 13; minY = 2; maxY = 8.5;
      } else if (selectedRange == RANGE_12M) {
        maxX = 12; minY = 2; maxY = 12;
      } else {
        minX = 12; maxX = 24; minY = 7; maxY = 16;
      }
    } else if (selectedType == TYPE_HEIGHT) {
      if (selectedRange == RANGE_13W) {
        maxX = 13; minY = 45; maxY = 66;
      } else if (selectedRange == RANGE_12M) {
        maxX = 12; minY = 46; maxY = 81;
      } else {
        minX = 12; maxX = 24; minY = 68; maxY = 94;
      }
    } else if (selectedType == TYPE_BMI) {
      if (selectedRange == RANGE_13W) {
        maxX = 13; minY = 10; maxY = 20;
      } else if (selectedRange == RANGE_12M) {
        maxX = 12; minY = 11; maxY = 20.5;
      } else {
        minX = 12; maxX = 24; minY = 13; maxY = 20;
      }
    }

    return Scaffold(
      backgroundColor: cs.background,
      body: Column(
        children: [
          // 顶部 Tab
          Container(
            height: 80,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ToggleTabButton(
                  label: S.of(context)?.weight ?? 'Weight',
                  iconPath: 'assets/icons/formula_milk.png',
                  isSelected: selectedType == TYPE_WEIGHT,
                  onTap: () async {
                    setState(() => selectedType = TYPE_WEIGHT);
                    await _refreshAll();
                  },
                ),
                ToggleTabButton(
                  label: S.of(context)?.height ?? 'Height',
                  iconPath: 'assets/icons/water.png',
                  isSelected: selectedType == TYPE_HEIGHT,
                  onTap: () async {
                    setState(() => selectedType = TYPE_HEIGHT);
                    await _refreshAll();
                  },
                ),
                ToggleTabButton(
                  label: 'BMI',
                  iconPath: 'assets/icons/poop.png',
                  isSelected: selectedType == TYPE_BMI,
                  onTap: () async {
                    setState(() => selectedType = TYPE_BMI);
                    await _refreshAll();
                  },
                ),
              ],
            ),
          ),
          // 范围选择居中
          Container(
            height: 60,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRangeRadio(RANGE_13W, S.of(context)?.range0to13Week ?? '0-13 Weeks'),
                _buildRangeRadio(RANGE_12M, S.of(context)?.range0to12Month ?? '0-12 Months'),
                _buildRangeRadio(RANGE_24M, S.of(context)?.range12to24Month ?? '12-24 Months'),
              ],
            ),
          ),
          // 折线图
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: LineChart(
                LineChartData(
                  lineTouchData: const LineTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: tt.bodySmall?.copyWith(color: cs.onBackground),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: tt.bodySmall?.copyWith(color: cs.onBackground),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: cs.outline)),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(color: cs.outline, strokeWidth: 0.5),
                    getDrawingVerticalLine: (value) => FlLine(color: cs.outline, strokeWidth: 0.5),
                  ),
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    // 虚线
                    ...List.generate(
                      selectedData.length,
                          (index) => LineChartBarData(
                        spots: selectedData[index],
                        isCurved: true,
                        color: lineColors[index % lineColors.length],
                        barWidth: 2,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(show: false),
                        dashArray: [6, 3],
                      ),
                    ),
                    // 宝宝线
                    LineChartBarData(
                      spots: babySeries,
                      isCurved: true,
                      color: cs.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 图例 + +号
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(lineColors[0], '3%'),
                      const SizedBox(width: 8),
                      _buildLegend(lineColors[1], '50%'),
                      const SizedBox(width: 8),
                      _buildLegend(lineColors[2], '97%'),
                    ],
                  ),
                ),
                // +号
                if (selectedType != TYPE_BMI)
                  GestureDetector(
                    onTap: _showAddDataDialog,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.add, color: cs.onPrimary, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeRadio(String value, String label) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: selectedRange,
          onChanged: (val) async {
            if (val != null) {
              setState(() => selectedRange = val);
              await _refreshAll();
            }
          },
          fillColor: MaterialStateProperty.all(cs.primary),
        ),
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface, fontSize: 12)),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 20, height: 2, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
