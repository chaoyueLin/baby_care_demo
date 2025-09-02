import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../common/db_provider.dart';
import '../models/baby.dart';
import '../models/baby_care.dart';

/// 时间范围选项
enum FeedRange { week, month, quarter }

class DataPage extends StatefulWidget {
  const DataPage({Key? key}) : super(key: key);

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  Baby? currentBaby;
  bool _loadingBaby = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentBabyAndData();
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
    setState(() => _loadingBaby = false);
  }

  Future<void> _refreshAll() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingBaby) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentBaby == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('未找到宝宝数据'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadCurrentBabyAndData(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          DailyFeedingChartAllInOne(
            babyId: currentBaby!.id!,
          ),
        ],
      ),
    );
  }
}

/// ---------------- DailyFeedingChartAllInOne ----------------

class DailyFeedingChartAllInOne extends StatefulWidget {
  final int babyId;
  final DateTime? initialDay;
  final double barWidth;

  const DailyFeedingChartAllInOne({
    super.key,
    required this.babyId,
    this.initialDay,
    this.barWidth = 10,
  });

  @override
  State<DailyFeedingChartAllInOne> createState() =>
      _DailyFeedingChartAllInOneState();
}

class _DailyFeedingChartAllInOneState extends State<DailyFeedingChartAllInOne> {
  FeedRange _range = FeedRange.week;
  late DateTime _anchorDay;
  late Future<List<BabyCare>> _future;
  _DayStat? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDay ?? DateTime.now();
    _anchorDay = DateTime(now.year, now.month, now.day);
    _future = _load();
  }

  Future<List<BabyCare>> _load() async {
    final dbp = DBProvider();
    final endExclusive =
        _anchorDay.add(const Duration(days: 1)).millisecondsSinceEpoch;
    final startMs = switch (_range) {
      FeedRange.week =>
      _anchorDay.subtract(const Duration(days: 6)).millisecondsSinceEpoch,
      FeedRange.month =>
      _anchorDay.subtract(const Duration(days: 29)).millisecondsSinceEpoch,
      FeedRange.quarter =>
      _anchorDay.subtract(const Duration(days: 89)).millisecondsSinceEpoch,
    };
    return dbp.getCareByRange(startMs, endExclusive, widget.babyId);
  }

  void _setRange(FeedRange r) {
    setState(() {
      _range = r;
      _future = _load();
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 时间范围选择
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Radio<FeedRange>(
                    value: FeedRange.week,
                    groupValue: _range,
                    onChanged: (v) => _setRange(FeedRange.week)),
                const Text('最近一周'),
              ],
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Radio<FeedRange>(
                    value: FeedRange.month,
                    groupValue: _range,
                    onChanged: (v) => _setRange(FeedRange.month)),
                const Text('最近一个月'),
              ],
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Radio<FeedRange>(
                    value: FeedRange.quarter,
                    groupValue: _range,
                    onChanged: (v) => _setRange(FeedRange.quarter)),
                const Text('最近三个月'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<BabyCare>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              return SizedBox(
                  height: 300,
                  child: Center(child: Text('数据加载失败：${snap.error}')));
            }
            final list = snap.data ?? const <BabyCare>[];
            final days = _range == FeedRange.week
                ? 7
                : _range == FeedRange.month
                ? 30
                : 90;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 图例
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.blue.shade400, '母乳'),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.green.shade400, '奶粉'),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.orange.shade400, '水'),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: _range == FeedRange.quarter
                      ? _DailyStackedChartScrollable(
                    records: list,
                    endDayInclusive: _anchorDay,
                    days: days,
                    barWidth: widget.barWidth,
                    onBarTapped: (dayStat) {
                      setState(() {
                        _selectedDay = dayStat;
                      });
                    },
                  )
                      : _DailyStackedChart(
                    records: list,
                    endDayInclusive: _anchorDay,
                    days: days,
                    barWidth: widget.barWidth,
                    onBarTapped: (dayStat) {
                      setState(() {
                        _selectedDay = dayStat;
                      });
                    },
                  ),
                ),
                if (_selectedDay != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '日期: ${_selectedDay!.day.year}-${_selectedDay!.day.month}-${_selectedDay!.day.day}\n母乳: ${_selectedDay!.milk.toInt()}ml, 奶粉: ${_selectedDay!.formula.toInt()}ml, 饮水: ${_selectedDay!.water.toInt()}ml, 💩: ${_selectedDay!.poopCount} 次',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _DailyStackedChartScrollable extends StatelessWidget {
  final List<BabyCare> records;
  final DateTime endDayInclusive;
  final int days;
  final double barWidth;
  final Function(_DayStat) onBarTapped;

  const _DailyStackedChartScrollable({
    required this.records,
    required this.endDayInclusive,
    required this.days,
    required this.onBarTapped,
    this.barWidth = 10,
  });

  @override
  Widget build(BuildContext context) {
    final agg = _aggregateByDay(records, endDayInclusive, days);
    final maxStackY = agg.maxStackY == 0 ? 100 : agg.maxStackY;
    final maxY = _niceCeil(maxStackY * 1.15);

    // 生成柱状图数据
    final groups = List.generate(agg.series.length, (i) {
      final s = agg.series[i];
      final milk = s.milk;
      final formula = s.formula;
      final water = s.water;
      final total = milk + formula + water;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total,
            width: barWidth,
            rodStackItems: [
              if (milk > 0) BarChartRodStackItem(0, milk, Colors.blue.shade400),
              if (formula > 0)
                BarChartRodStackItem(
                    milk, milk + formula, Colors.green.shade400),
              if (water > 0)
                BarChartRodStackItem(
                    milk + formula, total, Colors.orange.shade400),
            ],
            borderSide:
                BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ],
      );
    });

    return SizedBox(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧固定Y轴
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final v = (maxY / 4 * (4 - i)).round();
              return SizedBox(
                height: 300 / 5,
                child: Text(
                  v.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }),
          ),
          const SizedBox(width: 4),
          // 左侧分割线
          const SizedBox(
            width: 1,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
            ),
          ),
          const SizedBox(width: 4),
          // 横向滚动柱状图
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: groups.length * (barWidth + 8), // bar总宽度
                height: 300,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barGroups: groups,
                    gridData: FlGridData(show: false),
                    // 不要内部网格线
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, m) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= agg.series.length) {
                              return const SizedBox.shrink();
                            }
                            final d = agg.series[idx].day;
                            final totalBars = agg.series.length;
                            final step = totalBars <= 10
                                ? 1
                                : totalBars <= 20
                                    ? 2
                                    : totalBars <= 40
                                        ? 4
                                        : 7;
                            if (idx % step == 0) {
                              return Text('${d.month}/${d.day}',
                                  style: Theme.of(context).textTheme.bodySmall);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (_, __, ___, ____) =>
                            null, // 禁止tooltip浮窗
                      ),
                      touchCallback: (event, response) {
                        if (response == null || response.spot == null) return;
                        final idx = response.spot!.touchedBarGroupIndex;
                        if (idx < 0 || idx >= agg.series.length) return;
                        onBarTapped(agg.series[idx]);
                      },
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

  /// 聚合每日数据
  _AggDay _aggregateByDay(
      List<BabyCare> list, DateTime endDayInclusive, int days) {
    final end = DateTime(
            endDayInclusive.year, endDayInclusive.month, endDayInclusive.day)
        .add(const Duration(days: 1));
    final start = end.subtract(Duration(days: days));
    final series = <_DayStat>[];
    final indexOfDay = <String, int>{};

    DateTime cursor = start;
    while (cursor.isBefore(end)) {
      final key = _key(cursor);
      indexOfDay[key] = series.length;
      series.add(_DayStat(day: cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    double maxStackY = 0;

    for (final r in list) {
      if (r.date == null) continue;
      final t = DateTime.fromMillisecondsSinceEpoch(r.date!);
      if (t.isBefore(start) || !t.isBefore(end)) continue;
      final d = DateTime(t.year, t.month, t.day);
      final idx = indexOfDay[_key(d)];
      if (idx == null) continue;
      final s = series[idx];
      if (r.type == FeedType.poop) {
        s.poopCount += 1;
        continue;
      }
      final amount = double.tryParse(r.mush.trim()) ?? 0;
      switch (r.type) {
        case FeedType.milk:
          s.milk += amount;
          break;
        case FeedType.formula:
          s.formula += amount;
          break;
        case FeedType.babyFood:
          s.water += amount;
          break;
        case FeedType.poop:
          break;
      }
      final total = s.milk + s.formula + s.water;
      if (total > maxStackY) maxStackY = total;
    }

    return _AggDay(series: series, maxStackY: maxStackY);
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
 }

class _DailyStackedChart extends StatelessWidget {
  final List<BabyCare> records;
  final DateTime endDayInclusive;
  final int days;
  final double barWidth;
  final Function(_DayStat) onBarTapped;

  const _DailyStackedChart({
    required this.records,
    required this.endDayInclusive,
    required this.days,
    required this.onBarTapped,
    this.barWidth = 10,
  });

  @override
  Widget build(BuildContext context) {
    final agg = _aggregateByDay(records, endDayInclusive, days);
    final maxStackY = agg.maxStackY == 0 ? 100 : agg.maxStackY;
    final maxY = _niceCeil(maxStackY * 1.15);

    final groups = List.generate(agg.series.length, (i) {
      final s = agg.series[i];
      final milk = s.milk;
      final formula = s.formula;
      final water = s.water;
      final total = milk + formula + water;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total,
            width: barWidth,
            rodStackItems: [
              if (milk > 0) BarChartRodStackItem(0, milk, Colors.blue.shade400),
              if (formula > 0)
                BarChartRodStackItem(
                    milk, milk + formula, Colors.green.shade400),
              if (water > 0)
                BarChartRodStackItem(
                    milk + formula, total, Colors.orange.shade400),
            ],
            borderSide:
                BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ],
        showingTooltipIndicators: total > 0 || s.poopCount > 0 ? [0] : [],
        barsSpace: 4,
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          horizontalInterval: _chooseGridInterval(maxY),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: _chooseGridInterval(maxY),
              getTitlesWidget: (v, m) => Text(
                v == 0 ? '0' : v.toInt().toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= agg.series.length)
                  return const SizedBox.shrink();
                final d = agg.series[idx].day;
                final totalBars = agg.series.length;
                final step = totalBars <= 10
                    ? 1
                    : totalBars <= 20
                        ? 2
                        : totalBars <= 40
                            ? 4
                            : 7;
                if (idx % step == 0) {
                  return Text('${d.month}/${d.day}',
                      style: Theme.of(context).textTheme.bodySmall);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
            left: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (_, __, ___, ____) => null, // 👈 这里禁掉浮窗
          ),
          touchCallback: (event, response) {
            if (response == null || response.spot == null) return;
            final idx = response.spot!.touchedBarGroupIndex;
            if (idx < 0 || idx >= agg.series.length) return;
            onBarTapped(agg.series[idx]);
          },
        ),
      ),
    );
  }

  _AggDay _aggregateByDay(
      List<BabyCare> list, DateTime endDayInclusive, int days) {
    final end = DateTime(
            endDayInclusive.year, endDayInclusive.month, endDayInclusive.day)
        .add(const Duration(days: 1));
    final start = end.subtract(Duration(days: days));
    final series = <_DayStat>[];
    final indexOfDay = <String, int>{};

    DateTime cursor = start;
    while (cursor.isBefore(end)) {
      final key = _key(cursor);
      indexOfDay[key] = series.length;
      series.add(_DayStat(day: cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    double maxStackY = 0;

    for (final r in list) {
      if (r.date == null) continue;
      final t = DateTime.fromMillisecondsSinceEpoch(r.date!);
      if (t.isBefore(start) || !t.isBefore(end)) continue;
      final d = DateTime(t.year, t.month, t.day);
      final idx = indexOfDay[_key(d)];
      if (idx == null) continue;
      final s = series[idx];
      if (r.type == FeedType.poop) {
        s.poopCount += 1;
        continue;
      }
      final amount = double.tryParse(r.mush.trim()) ?? 0;
      switch (r.type) {
        case FeedType.milk:
          s.milk += amount;
          break;
        case FeedType.formula:
          s.formula += amount;
          break;
        case FeedType.babyFood:
          s.water += amount;
          break;
        case FeedType.poop:
          break;
      }
      final total = s.milk + s.formula + s.water;
      if (total > maxStackY) maxStackY = total;
    }

    return _AggDay(series: series, maxStackY: maxStackY);
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class _DayStat {
  final DateTime day;
  double milk = 0;
  double formula = 0;
  double water = 0;
  int poopCount = 0;

  _DayStat({required this.day});
}

class _AggDay {
  final List<_DayStat> series;
  final double maxStackY;

  _AggDay({required this.series, required this.maxStackY});
}

double _niceCeil(double v) {
  if (v <= 100) return 100;
  if (v <= 200) return 200;
  if (v <= 300) return 300;
  if (v <= 500) return 500;
  if (v <= 800) return 800;
  if (v <= 1000) return 1000;
  final k = (v / 200).ceil();
  return (k * 200).toDouble();
}

double _chooseGridInterval(double maxY) {
  if (maxY <= 200) return 50;
  if (maxY <= 500) return 100;
  if (maxY <= 1000) return 200;
  return 250;
}
