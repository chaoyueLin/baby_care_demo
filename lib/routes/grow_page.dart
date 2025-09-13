import 'package:baby_care_demo/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:baby_care_demo/models/grow_standard.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as dtp;
import '../common/db_provider.dart';
import '../models/baby.dart';
import '../models/baby_grow.dart';
import '../utils/dialog_util.dart';
import '../widget/custom_tab_button.dart';
import 'image_preview.dart';

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

    try {
      if (selectedType == TYPE_BMI) {
        // 1. 查询体重
        final weightList = await DBProvider().getBabyGrows(
          babyId: currentBaby!.id ?? 0,
          type: GrowType.weight,
          startMs: start.millisecondsSinceEpoch,
          endMs: end.millisecondsSinceEpoch,
        );

        // 2. 查询身高
        final heightList = await DBProvider().getBabyGrows(
          babyId: currentBaby!.id ?? 0,
          type: GrowType.height,
          startMs: start.millisecondsSinceEpoch,
          endMs: end.millisecondsSinceEpoch,
        );

        // 3. 按日期对齐
        final Map<String, double> weightMap = {};
        for (final g in weightList) {
          final d = DateTime.fromMillisecondsSinceEpoch(g.date ?? 0);
          final key = "${d.year}-${d.month}-${d.day}";
          weightMap[key] = double.tryParse(g.mush ?? '') ?? 0;
        }

        final spots = <FlSpot>[];
        for (final g in heightList) {
          final d = DateTime.fromMillisecondsSinceEpoch(g.date ?? 0);
          final key = "${d.year}-${d.month}-${d.day}";
          if (weightMap.containsKey(key)) {
            final weight = weightMap[key]!;
            final heightCm = double.tryParse(g.mush ?? '') ?? 0;
            if (weight > 0 && heightCm > 0) {
              final heightM = heightCm / 100.0;
              final bmi = weight / (heightM * heightM);
              final x = _calcXByBirth(birth, d);
              final xAdj = (selectedRange == RANGE_24M) ? x.clamp(12.0, 24.0) : x;
              spots.add(FlSpot(xAdj, bmi));
            }
          }
        }

        spots.sort((a, b) => a.x.compareTo(b.x));
        babySeries = spots;
      } else {
        // weight / height 走原来的逻辑
        final type = _toGrowType(selectedType);
        if (type == null) return;

        final list = await DBProvider().getBabyGrows(
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
      }
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
    if (selectedType == TYPE_BMI) {
      // 🚫 BMI 不允许手动添加
      ToastUtil.showToast("BMI 由体重和身高自动计算，不能手动添加");
      return;
    }

    _valueController.clear();
    _selectedDate = DateTime.now();

    DialogUtil.showStyledDialog(
      context: context,
      title: _getDialogTitle() ?? '',
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          final tt = Theme.of(context).textTheme;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  selectedType == TYPE_WEIGHT
                      ? "BMI = weight(kg) / (height(m)²)\n请输入宝宝体重 (kg)，超过 2 岁或超过 16kg 的数据不会显示在图表中"
                      : "BMI = weight(kg) / (height(m)²)\n请输入宝宝身高 (cm)，超过 2 岁或超过 94cm 的数据不会显示在图表中",
                  style: tt.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              TextField(
                controller: _valueController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
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
                    '${S.of(context)?.chooseDate ?? 'Choose Date'}: ${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context)?.cancel ?? '取消'),
        ),
        TextButton(
          onPressed: () async {
            await _saveGrowData();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(S.of(context)?.save ?? '保存'),
        ),
      ],
    );
  }


  void _showDatePicker(StateSetter setDialogState) {
    final min = currentBaby?.birthdate ?? DateTime(2000, 1, 1);
    final max = DateTime.now();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    dtp.DatePicker.showDatePicker(context,
        showTitleActions: true,
        minTime: min.isAfter(max) ? max : min,
        maxTime: max,
        currentTime: _selectedDate,
        onConfirm: (date) => setDialogState(() => _selectedDate = date),
        locale: _mapLocaleToPickerLocale(Localizations.localeOf(context)),
        theme: dtp.DatePickerTheme(
          backgroundColor: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
          headerColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.lightGreen,
          doneStyle: TextStyle(
            color: isDarkMode ? Colors.lightGreenAccent : Colors.white,
            fontSize: 16,
          ),
          cancelStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.white,
            fontSize: 16,
          ),
          itemStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : const Color(0xFF2D2D2D),
            fontSize: 16,
          ),
        ));
  }

  dtp.LocaleType _mapLocaleToPickerLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'zh': // 中文
        return dtp.LocaleType.zh;
      default:   // 默认英文
        return dtp.LocaleType.en;
    }
  }

  Future<void> _saveGrowData() async {
    if (_valueController.text.trim().isEmpty) return;
    if (currentBaby == null) {
      if (!mounted) return;
      ToastUtil.showToast("Please add or select a baby first");
      return;
    }

    final value = double.tryParse(_valueController.text.trim());
    if (value == null) {
      if (!mounted) return;
      ToastUtil.showToast("Please enter a valid value");
      return;
    }

    final growType = _toGrowType(selectedType);
    if (growType == null) {
      if (!mounted) return;

      ToastUtil.showToast("BMI 由体重和身高自动计算，不能手动添加");
      return;
    }

    final birth = currentBaby!.birthdate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final diff = _selectedDate.difference(birth).inDays;


    if (diff > 365 * 2) {
      final confirm = await DialogUtil.showConfirmDialog(
        context,
        title: "提示",
        content: "超过 2 岁的记录不会显示在图表中，是否仍要添加？",
      );
      if (confirm != true) return;
    }


    if (selectedType == TYPE_WEIGHT && value > 16) {
      final confirm = await DialogUtil.showConfirmDialog(
        context,
        title: "提示",
        content: "体重超过 16kg 的记录不会显示在图表中，是否仍要添加？",
      );
      if (confirm != true) return;
    }


    if (selectedType == TYPE_HEIGHT && value > 94) {
      final confirm = await DialogUtil.showConfirmDialog(
        context,
        title: "提示",
        content: "身高超过 94cm 的记录不会显示在图表中，是否仍要添加？",
      );
      if (confirm != true) return;
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
      ToastUtil.showToast("Data saved successfully");
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showToast("Save failed");
    }
  }


  String? _getDialogTitle() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return S.of(context)?.addWeight ?? 'Add Weight Data';
      case TYPE_HEIGHT:
        return S.of(context)?.addHeight ?? 'Add Height Data';
      case TYPE_BMI:
        return S.of(context)?.addBMI ?? 'Add BMI Data';
      default:
        return S.of(context)?.addData ?? 'Add Data';
    }
  }

  String? _getInputLabel() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return S.of(context)?.weight ?? 'Weight';
      case TYPE_HEIGHT:
        return S.of(context)?.height ?? 'Height';
      case TYPE_BMI:
        return S.of(context)?.bmi ?? 'BMI';
      default:
        return S.of(context)?.value ?? 'Value';
    }
  }

  String? _getInputHint() {
    switch (selectedType) {
      case TYPE_WEIGHT:
        return S.of(context)?.enterWeightKg ?? 'Please enter weight (kg)';
      case TYPE_HEIGHT:
        return S.of(context)?.enterHeightCm ?? 'Please enter height (cm)';
      case TYPE_BMI:
        return S.of(context)?.enterBMI ?? 'Please enter BMI';
      default:
        return S.of(context)?.enterValue ?? 'Please enter value';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final tertiary = cs.tertiary ?? cs.secondary;
    final lineColors = [
      Colors.lightGreen.shade200,
      Colors.lightGreen.shade300,
      Colors.lightGreen.shade400
    ];

    double maxX = 0, minX = 0, minY = 0, maxY = 0;
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
                _buildRangeRadio(
                    RANGE_13W, S.of(context)?.range0to13Week ?? '0-13 Weeks'),
                _buildRangeRadio(
                    RANGE_12M, S.of(context)?.range0to12Month ?? '0-12 Months'),
                _buildRangeRadio(RANGE_24M,
                    S.of(context)?.range12to24Month ?? '12-24 Months'),
              ],
            ),
          ),
          // 折线图
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 6.0),
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
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
                  borderData: FlBorderData(
                      show: true, border: Border.all(color: cs.outline)),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: cs.outline, strokeWidth: 0.5),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: cs.outline, strokeWidth: 0.5),
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
              crossAxisAlignment: CrossAxisAlignment.end,
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
                      const SizedBox(width: 8),
                      // + 号旁边的问号
                      GestureDetector(
                        onTap: _openPreview,
                        child: const Icon(Icons.help_outline, size: 16, color: Colors.grey),
                      )
                    ],
                  ),
                ),

                // +号
                Visibility(
                  visible: selectedType != TYPE_BMI,
                  maintainSize: true,
                  // 保持大小
                  maintainAnimation: true,
                  maintainState: true,
                  child: GestureDetector(
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
                )
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
        Text(label,
            style: tt.bodySmall?.copyWith(color: cs.onSurface, fontSize: 12)),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return GestureDetector(
      onTap: () {
        // 点击图例，打开图片预览
        _openPreview();
      },
      child: Row(
        children: [
          Container(width: 20, height: 2, color: color),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  void _openPreview() {
    List<String> listImagePaths = [];
    switch (selectedType) {
      case TYPE_WEIGHT:
        listImagePaths = [
          'assets/weight/wfa-boys-0-13-percentiles_page.jpg',
          'assets/weight/wfa-boys-0-5-percentiles_page.jpg',
          'assets/weight/wfa-girls-0-13-percentiles_page.jpg',
          'assets/weight/wfa-girls-0-5-percentiles_page.jpg',
        ];
        break;
      case TYPE_HEIGHT:
        listImagePaths = [
          'assets/height/lfa-boys-0-13-percentiles_page.jpg',
          'assets/height/lfa-boys-0-2-percentiles_page.jpg',
          'assets/height/lfa-girls-0-13-percentiles_page.jpg',
          'assets/height/lfa-girls-0-2-percentiles_page.jpg',
        ];
        break;
      case TYPE_BMI:
        listImagePaths = [
          'assets/bmi/bmi-boys-0-13-percentiles_page.jpg',
          'assets/bmi/bmi-boys-0-2-percentiles_page.jpg',
          'assets/bmi/bmi-girls-0-13-percentiles_page.jpg',
          'assets/bmi/bmi-girls-0-2-percentiles_page.jpg',
        ];
        break;
    }

    if (listImagePaths.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreview(
          images: listImagePaths,
        ),
      ),
    );
  }


}
