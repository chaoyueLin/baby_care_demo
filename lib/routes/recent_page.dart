import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import '../common/db_provider.dart';
import '../models/baby.dart';
import '../models/baby_care.dart';
import '../utils/date_util.dart';

/// 时间范围选项
enum FeedRange { week, month, quarter }

class RecentPage extends StatefulWidget {
  const RecentPage({Key? key}) : super(key: key);

  @override
  State<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends State<RecentPage> {
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final s = S.of(context);

    if (_loadingBaby) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentBaby == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s?.noBabyDataFound ?? 'No baby data found'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadCurrentBabyAndData(),
              child: Text(s?.retry ?? 'Retry'),
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
            baby: currentBaby!,
          ),
        ],
      ),
    );
  }
}

/// ---------------- DailyFeedingChartAllInOne ----------------

class DailyFeedingChartAllInOne extends StatefulWidget {
  final int babyId;
  final Baby baby;
  final DateTime? initialDay;
  final double barWidth;

  const DailyFeedingChartAllInOne({
    super.key,
    required this.babyId,
    required this.baby,
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

  DateTime get _babyBirthDay {
    if (widget.baby.birthdate != null) {
      final birthday = widget.baby.birthdate;
      return DateTime(birthday.year, birthday.month, birthday.day);
    }
    // 如果没有生日信息，默认返回一个很早的日期
    return DateTime(2000, 1, 1);
  }

  Future<List<BabyCare>> _load() async {
    final dbp = DBProvider();

    final days = switch (_range) {
      FeedRange.week => 7,
      FeedRange.month => 30,
      FeedRange.quarter => 90,
    };

    final endExclusive =
        _anchorDay.add(const Duration(days: 1)).millisecondsSinceEpoch;

    // 计算开始日期，但不能早于宝宝生日
    final calculatedStartDay = _anchorDay.subtract(Duration(days: days - 1));
    final actualStartDay = calculatedStartDay.isBefore(_babyBirthDay)
        ? _babyBirthDay
        : calculatedStartDay;
    final startMs = actualStartDay.millisecondsSinceEpoch;

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
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
                Text(s?.recentWeek ?? 'Recent Week',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurface, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 6),
            Row(
              children: [
                Radio<FeedRange>(
                    value: FeedRange.month,
                    groupValue: _range,
                    onChanged: (v) => _setRange(FeedRange.month)),
                Text(s?.recentMonth ?? 'Recent Month',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurface, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 6),
            Row(
              children: [
                Radio<FeedRange>(
                    value: FeedRange.quarter,
                    groupValue: _range,
                    onChanged: (v) => _setRange(FeedRange.quarter)),
                Text(s?.recentQuarter ?? 'Recent Quarter',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurface, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
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
                  child: Center(
                      child: Text(
                          '${s?.dataLoadingFailed ?? 'Data loading failed'}: ${snap.error}')));
            }
            final list = snap.data ?? const <BabyCare>[];
            final days = _getActualDays();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s?.sleepStats ?? "Sleep Stats", style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12,),
                SizedBox(
                  height: 200,
                  child: SleepLineChart(
                    records: list,
                    endDayInclusive: _anchorDay,
                    days: days,
                    babyBirthDay: _babyBirthDay,
                  ),
                ),
                // 图例
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                        Colors.blue.shade400, s?.breastMilk ?? "Breast Milk"),
                    const SizedBox(width: 12),
                    _buildLegendItem(
                        Colors.green.shade400, s?.formula ?? "Formula"),
                    const SizedBox(width: 12),
                    _buildLegendItem(
                        Colors.orange.shade400, s?.babyFood ?? "Baby Food"),
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
                    babyBirthDay: _babyBirthDay,
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
                    babyBirthDay: _babyBirthDay,
                    onBarTapped: (dayStat) {
                      setState(() {
                        _selectedDay = dayStat;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _selectedDay == null
                        ? ''
                        : '${DateUtil.dateToString(_selectedDay!.day)}:\n'
                        '${s?.breastMilk ?? 'Breast Milk'}: ${_selectedDay!.milk.toInt()}ml, '
                        '${s?.formula ?? 'Formula'}: ${_selectedDay!.formula.toInt()}ml, '
                        '${s?.babyFood ?? 'Baby Food'}: ${_selectedDay!.babyFood.toInt()}g, '
                        '${s?.poopCount ?? 'Poop'}: ${_selectedDay!.poopCount} ${s?.times ?? 'times'}, '
                        '${s?.sleep ?? 'Sleep'}: ${_selectedDay!.sleepHours.toStringAsFixed(1)}h',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),

              ],
            );
          },
        ),
      ],
    );
  }

  int _getActualDays() {
    final requestedDays = switch (_range) {
      FeedRange.week => 7,
      FeedRange.month => 30,
      FeedRange.quarter => 90,
    };

    // 计算从宝宝生日到当前日期的实际天数
    final daysSinceBirth = _anchorDay.difference(_babyBirthDay).inDays + 1;

    // 返回请求的天数和实际天数中的较小值
    return requestedDays < daysSinceBirth ? requestedDays : daysSinceBirth;
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

/// ---------------- SleepLineChart ----------------

class SleepLineChart extends StatelessWidget {
  final List<BabyCare> records;
  final DateTime endDayInclusive;
  final int days;
  final DateTime babyBirthDay;

  const SleepLineChart({
    super.key,
    required this.records,
    required this.endDayInclusive,
    required this.days,
    required this.babyBirthDay,
  });

  @override
  Widget build(BuildContext context) {
    final agg = _aggregateByDay(records, endDayInclusive, days, babyBirthDay);
    final series = agg.series;

    final spots = <FlSpot>[];
    for (int i = 0; i < series.length; i++) {
      spots.add(FlSpot(i.toDouble(), series[i].sleepHours));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 24,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _calculateInterval(series.length), // 使用固定间隔
                getTitlesWidget: (v, m) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= series.length) return const SizedBox.shrink();
                  final d = series[idx].day;
                  return Text('${d.month}/${d.day}', style: Theme.of(context).textTheme.bodySmall);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, m) {
                  if (v % 5 == 0) {
                    return Text(v.toInt().toString(), style: Theme.of(context).textTheme.bodySmall);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2,
              color: Colors.lightGreen,
              dotData: FlDotData(show: series.length <= 30),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(int totalDays) {
    if (totalDays <= 7) return 1.0;  // 7天内每天显示
    if (totalDays <= 14) return 2.0; // 14天内每2天显示
    if (totalDays <= 30) return (totalDays / 6).ceilToDouble(); // 30天内显示约6个
    if (totalDays <= 90) return (totalDays / 7).ceilToDouble(); // 90天内显示约7个
    return (totalDays / 7).ceilToDouble();
  }


  _AggDay _aggregateByDay(List<BabyCare> list, DateTime endDayInclusive, int days, DateTime babyBirthDay) {
    final end = DateTime(endDayInclusive.year, endDayInclusive.month, endDayInclusive.day)
        .add(const Duration(days: 1));
    final calculatedStart = end.subtract(Duration(days: days));
    final start = calculatedStart.isBefore(babyBirthDay) ? babyBirthDay : calculatedStart;

    final series = <_DayStat>[];
    final indexOfDay = <String, int>{};

    // 初始化每天
    for (DateTime cursor = start; cursor.isBefore(end); cursor = cursor.add(const Duration(days: 1))) {
      final key =
          '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      indexOfDay[key] = series.length;
      series.add(_DayStat(day: cursor));
    }

    double maxMilkFormula = 0;
    double maxBabyFood = 0;

    for (final r in list) {
      if (r.date != null && r.mush.isNotEmpty) {
        // 处理睡眠
        final sleepStart = DateTime.fromMillisecondsSinceEpoch(r.date!);
        final durationMs = int.tryParse(r.mush) ?? 0;
        final sleepEnd = sleepStart.add(Duration(milliseconds: durationMs));

        DateTime current = sleepStart;
        while (current.isBefore(sleepEnd)) {
          final dayStart = DateTime(current.year, current.month, current.day);
          // 修复：使用下一天的开始时间，而不是当天的结束时间
          final nextDayStart = DateTime(current.year, current.month, current.day + 1);
          final effectiveEnd = sleepEnd.isBefore(nextDayStart) ? sleepEnd : nextDayStart;

          final key =
              '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
          final idx = indexOfDay[key];
          if (idx != null) {
            // 修复：计算准确的分钟数，不添加额外的1秒
            final sleepMinutes = effectiveEnd.difference(current).inMinutes;
            series[idx].sleepHours += sleepMinutes / 60.0;
          }

          // 修复：直接移动到下一天开始，不添加1秒
          current = effectiveEnd;
        }
      }
    }

    return _AggDay(
      series: series,
      maxMilkFormula: maxMilkFormula,
      maxBabyFood: maxBabyFood,
    );
  }
}


class _DailyStackedChartScrollable extends StatelessWidget {
  final List<BabyCare> records;
  final DateTime endDayInclusive;
  final int days;
  final double barWidth;
  final DateTime babyBirthDay;
  final Function(_DayStat) onBarTapped;

  const _DailyStackedChartScrollable({
    required this.records,
    required this.endDayInclusive,
    required this.days,
    required this.onBarTapped,
    required this.babyBirthDay,
    this.barWidth = 10,
  });

  @override
  Widget build(BuildContext context) {
    final agg = _aggregateByDay(records, endDayInclusive, days, babyBirthDay);
    final maxMilkFormula = agg.maxMilkFormula == 0 ? 100 : agg.maxMilkFormula;
    final maxBabyFood = agg.maxBabyFood == 0 ? 50 : agg.maxBabyFood;
    final maxY = _niceCeil(
        (maxMilkFormula > maxBabyFood ? maxMilkFormula : maxBabyFood) * 1.15);

    final groups = List.generate(agg.series.length, (i) {
      final s = agg.series[i];
      final milk = s.milk;
      final formula = s.formula;
      final babyFood = s.babyFood;

      final rods = <BarChartRodData>[];

      if (milk > 0 || formula > 0) {
        rods.add(
          BarChartRodData(
            toY: milk + formula,
            width: barWidth,
            rodStackItems: [
              if (milk > 0) BarChartRodStackItem(0, milk, Colors.blue.shade400),
              if (formula > 0)
                BarChartRodStackItem(
                    milk, milk + formula, Colors.green.shade400),
            ],
            borderSide:
            BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        );
      }

      if (babyFood > 0) {
        rods.add(
          BarChartRodData(
            toY: babyFood,
            width: barWidth,
            color: Colors.orange.shade400,
            borderSide:
            BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        );
      }

      return BarChartGroupData(x: i, barRods: rods, barsSpace: 6);
    });

    return SizedBox(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(
            width: 1,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: groups.length * (barWidth * 2 + 12),
                height: 300,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barGroups: groups,
                    gridData: FlGridData(show: false),
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
                        getTooltipItem: (_, __, ___, ____) => null,
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

  _AggDay _aggregateByDay(
      List<BabyCare> list, DateTime endDayInclusive, int days, DateTime babyBirthDay) {
    final end = DateTime(
        endDayInclusive.year, endDayInclusive.month, endDayInclusive.day)
        .add(const Duration(days: 1));
    final calculatedStart = end.subtract(Duration(days: days));
    final start = calculatedStart.isBefore(babyBirthDay) ? babyBirthDay : calculatedStart;
    final series = <_DayStat>[];
    final indexOfDay = <String, int>{};

    DateTime cursor = start;
    while (cursor.isBefore(end)) {
      final key = _key(cursor);
      indexOfDay[key] = series.length;
      series.add(_DayStat(day: cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    double maxMilkFormula = 0;
    double maxBabyFood = 0;

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
          s.babyFood += amount;
          break;
        case FeedType.poop:
          break;
        case FeedType.sleep:
          break;
      }
      if (s.milk + s.formula > maxMilkFormula) {
        maxMilkFormula = s.milk + s.formula;
      }
      if (s.babyFood > maxBabyFood) {
        maxBabyFood = s.babyFood;
      }
    }

    return _AggDay(
        series: series,
        maxMilkFormula: maxMilkFormula,
        maxBabyFood: maxBabyFood);
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class _DailyStackedChart extends StatelessWidget {
  final List<BabyCare> records;
  final DateTime endDayInclusive;
  final int days;
  final double barWidth;
  final DateTime babyBirthDay;
  final Function(_DayStat) onBarTapped;

  const _DailyStackedChart({
    required this.records,
    required this.endDayInclusive,
    required this.days,
    required this.onBarTapped,
    required this.babyBirthDay,
    this.barWidth = 10,
  });

  @override
  Widget build(BuildContext context) {
    final agg = _aggregateByDay(records, endDayInclusive, days, babyBirthDay);
    final maxMilkFormula = agg.maxMilkFormula == 0 ? 100 : agg.maxMilkFormula;
    final maxBabyFood = agg.maxBabyFood == 0 ? 50 : agg.maxBabyFood;
    final maxY = _niceCeil(
        (maxMilkFormula > maxBabyFood ? maxMilkFormula : maxBabyFood) * 1.15);

    final groups = List.generate(agg.series.length, (i) {
      final s = agg.series[i];
      final milk = s.milk;
      final formula = s.formula;
      final babyFood = s.babyFood;

      final rods = <BarChartRodData>[];

      if (milk > 0 || formula > 0) {
        rods.add(
          BarChartRodData(
            toY: milk + formula,
            width: barWidth,
            rodStackItems: [
              if (milk > 0) BarChartRodStackItem(0, milk, Colors.blue.shade400),
              if (formula > 0)
                BarChartRodStackItem(
                    milk, milk + formula, Colors.green.shade400),
            ],
            borderSide:
            BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        );
      }

      if (babyFood > 0) {
        rods.add(
          BarChartRodData(
            toY: babyFood,
            width: barWidth,
            color: Colors.orange.shade400,
            borderSide:
            BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        );
      }

      return BarChartGroupData(
        x: i,
        barRods: rods,
        barsSpace: 6,
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
            getTooltipItem: (_, __, ___, ____) => null,
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
      List<BabyCare> list, DateTime endDayInclusive, int days, DateTime babyBirthDay) {
    final end = DateTime(
        endDayInclusive.year, endDayInclusive.month, endDayInclusive.day)
        .add(const Duration(days: 1));
    final calculatedStart = end.subtract(Duration(days: days));
    final start = calculatedStart.isBefore(babyBirthDay) ? babyBirthDay : calculatedStart;
    final series = <_DayStat>[];
    final indexOfDay = <String, int>{};

    DateTime cursor = start;
    while (cursor.isBefore(end)) {
      final key = _key(cursor);
      indexOfDay[key] = series.length;
      series.add(_DayStat(day: cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    double maxMilkFormula = 0;
    double maxBabyFood = 0;

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
          s.babyFood += amount;
          break;
        case FeedType.poop:
          break;
        case FeedType.sleep:
          break;
      }
      if (s.milk + s.formula > maxMilkFormula) {
        maxMilkFormula = s.milk + s.formula;
      }
      if (s.babyFood > maxBabyFood) {
        maxBabyFood = s.babyFood;
      }
    }

    return _AggDay(
        series: series,
        maxMilkFormula: maxMilkFormula,
        maxBabyFood: maxBabyFood);
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

/// ---------------- 公用类 ----------------

class _DayStat {
  final DateTime day;
  double milk = 0;
  double formula = 0;
  double babyFood = 0; // g
  int poopCount = 0;
  double sleepHours = 0; // 新增：睡眠时长（小时）

  _DayStat({required this.day});
}

class _AggDay {
  final List<_DayStat> series;
  final double maxMilkFormula;
  final double maxBabyFood;

  _AggDay({
    required this.series,
    required this.maxMilkFormula,
    required this.maxBabyFood,
  });
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