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
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<Color> lineColors = const [Colors.blue, Colors.red, Colors.green];

  static const String TYPE_WEIGHT = 'weight';
  static const String TYPE_HEIGHT = 'height';
  static const String TYPE_BMI = 'bmi';

  static const String RANGE_13W = '0-13w';
  static const String RANGE_12M = '0-12m';
  static const String RANGE_24M = '12-24m';

  String selectedType = TYPE_WEIGHT;
  String selectedRange = RANGE_13W;

  // WHO/国家标准曲线数据
  List<List<FlSpot>> selectedData = [];
  // 宝宝自己的测量曲线
  List<FlSpot> babySeries = [];

  Baby? currentBaby;

  // 输入弹窗
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

  /// 获取当前 baby 并加载曲线数据
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

  bool isBoy() => (currentBaby?.sex ?? 1) == 1; // 默认男宝

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

  /// 依据宝宝生日计算横坐标
  /// RANGE_13W 使用周(0~13)，其他范围使用月(0~24)，并对 12-24 月保留 12~24 段
  double _calcXByBirth(DateTime birth, DateTime when) {
    final diffDays = when.difference(birth).inDays.toDouble();
    if (selectedRange == RANGE_13W) {
      return diffDays / 7.0; // 周
    } else {
      // 使用平均月长，避免复杂历法计算
      return diffDays / 30.4375; // 月
    }
  }

  /// 加载宝宝自己的测量数据并转换成 FlSpot
  Future<void> _loadBabySeries() async {
    babySeries = [];
    if (currentBaby == null) return;

    final birth = currentBaby!.birthdate ?? DateTime.fromMillisecondsSinceEpoch(0);

    // 计算当前选择范围的起止时间
    DateTime start, end;
    if (selectedRange == RANGE_13W) {
      start = birth;
      end = birth.add(const Duration(days: 13 * 7));
    } else if (selectedRange == RANGE_12M) {
      start = birth;
      end = birth.add(const Duration(days: 365));
    } else {
      start = birth.add(const Duration(days: 365));
      end = birth.add(const Duration(days: (365 * 2))); // 近似 24 个月
    }

    final type = _toGrowType(selectedType);
    if (type == null) return; // BMI 使用计算，不直接录入

    try {
      // 你需要在 DBProvider 中实现该方法
      // 返回指定 baby、类型、时间范围内的记录，按时间升序
      final List<BabyGrow> list = await DBProvider().getBabyGrows(
        babyId: currentBaby!.id ?? 0,
        type: type,
        startMs: start.millisecondsSinceEpoch,
        endMs: end.millisecondsSinceEpoch,
      );

      final spots = <FlSpot>[];
      for (final g in list) {
        final t = DateTime.fromMillisecondsSinceEpoch(g.date??0);
        final x = _calcXByBirth(birth, t);
        // 12-24 月范围内，x 需要位于 [12,24]
        final xAdj = (selectedRange == RANGE_24M)
            ? x.clamp(12.0, 24.0)
            : x;
        final y = double.tryParse(g.mush ?? '') ?? 0.0;
        if (y > 0) spots.add(FlSpot(xAdj, y));
      }

      spots.sort((a, b) => a.x.compareTo(b.x));
      babySeries = spots;
    } catch (e) {
      // 如果方法名不同，可改为你现有的查询接口
      // 例如：final list = await DBProvider().queryGrowByBabyAndType(...);
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

  /// 添加数据弹窗
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
                  TextField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _getInputLabel(),
                      hintText: _getInputHint(),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showDatePicker(setDialogState),
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
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    await _saveGrowData();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 日期选择器
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

  /// 保存成长数据 -> 插入 DB -> 刷新曲线
  Future<void> _saveGrowData() async {
    if (_valueController.text.trim().isEmpty) return;
    if (currentBaby == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加或选择一个宝宝')),
      );
      return;
    }

    final value = double.tryParse(_valueController.text.trim());
    if (value == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的数值')),
      );
      return;
    }

    final growType = _toGrowType(selectedType);
    if (growType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BMI 数据需要通过身高和体重计算获得')),
      );
      return;
    }

    final growData = BabyGrow(
      babyId: currentBaby!.id ?? 0,
      date: _selectedDate.millisecondsSinceEpoch,
      type: growType,
      mush: value.toString(), // "120" 这种无单位字符串
    );

    try {
      await DBProvider().insertGrow(growData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数据保存成功')),
      );
      // 重新拉取宝宝曲线
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  String _getDialogTitle() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return '添加体重数据';
      case TYPE_HEIGHT:
        return '添加身高数据';
      case TYPE_BMI:
        return '添加 BMI 数据';
      default:
        return '添加数据';
    }
  }

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

  String _getInputHint() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return '请输入体重 (kg)';
      case TYPE_HEIGHT:
        return '请输入身高 (cm)';
      case TYPE_BMI:
        return '请输入 BMI';
      default:
        return '请输入数值';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 坐标轴范围
    double maxX = 0, minX = 0, minY = 0, maxY = 0, intervalX = 1, intervalY = 1;

    if (selectedType == TYPE_WEIGHT) {
      if (selectedRange == RANGE_13W) {
        maxX = 13;
        minY = 2;
        maxY = 8.5;
      } else if (selectedRange == RANGE_12M) {
        maxX = 12;
        minY = 2;
        maxY = 12;
      } else {
        minX = 12;
        maxX = 24;
        minY = 7;
        maxY = 16;
      }
    } else if (selectedType == TYPE_HEIGHT) {
      if (selectedRange == RANGE_13W) {
        maxX = 13;
        minY = 45;
        maxY = 66;
      } else if (selectedRange == RANGE_12M) {
        maxX = 12;
        minY = 46;
        maxY = 81;
      } else {
        minX = 12;
        maxX = 24;
        minY = 68;
        maxY = 94;
      }
    } else if (selectedType == TYPE_BMI) {
      if (selectedRange == RANGE_13W) {
        maxX = 13;
        minY = 10;
        maxY = 20;
      } else if (selectedRange == RANGE_12M) {
        maxX = 12;
        minY = 11;
        maxY = 20.5;
      } else {
        minX = 12;
        maxX = 24;
        minY = 13;
        maxY = 20;
      }
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
                  label: S.of(context)?.formula ?? 'Weight',
                  iconPath: 'assets/icons/formula_milk.png',
                  onTap: () async {
                    setState(() => selectedType = TYPE_WEIGHT);
                    await _refreshAll();
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.water ?? 'Height',
                  iconPath: 'assets/icons/water.png',
                  onTap: () async {
                    setState(() => selectedType = TYPE_HEIGHT);
                    await _refreshAll();
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.poop ?? 'BMI',
                  iconPath: 'assets/icons/poop.png',
                  onTap: () async {
                    setState(() => selectedType = TYPE_BMI);
                    await _refreshAll();
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
                        onChanged: (value) async {
                          setState(() => selectedRange = value!);
                          await _refreshAll();
                        },
                      ),
                      const Text('0-13周'),
                      const SizedBox(width: 8),
                      Radio<String>(
                        value: RANGE_12M,
                        groupValue: selectedRange,
                        onChanged: (value) async {
                          setState(() => selectedRange = value!);
                          await _refreshAll();
                        },
                      ),
                      const Text('0-12个月'),
                      const SizedBox(width: 8),
                      Radio<String>(
                        value: RANGE_24M,
                        groupValue: selectedRange,
                        onChanged: (value) async {
                          setState(() => selectedRange = value!);
                          await _refreshAll();
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
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: LineChart(
                LineChartData(
                  lineTouchData: const LineTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 2.0),
                          child: Text(value.toStringAsFixed(1)),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 0.0),
                          child: Text(value.toInt().toString()),
                        ),
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
                  // 先画标准曲线
                  lineBarsData: [
                    ...List.generate(
                      selectedData.length,
                          (index) => _lineChartBarData(
                        selectedData[index],
                        lineColors[index % lineColors.length],
                        showDots: false,
                        width: 3,
                      ),
                    ),
                    // 最后叠加宝宝曲线（黄色）
                    _lineChartBarData(
                      babySeries,
                      Colors.yellow,
                      showDots: true,
                      width: 3.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineChartBarData(
      List<FlSpot> spots,
      Color color, {
        bool showDots = false,
        double width = 3,
      }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: width,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(show: false),
      dotData: FlDotData(show: showDots),
    );
  }
}
