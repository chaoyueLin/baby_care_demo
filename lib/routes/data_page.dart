import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
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
    if (_loadingBaby) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentBaby == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No baby data found'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadCurrentBabyAndData(),
              child: const Text('Retry'),
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
                Text(S.of(context)?.recentWeek ?? 'Recent Week',style: tt.bodySmall?.copyWith(color: cs.onSurface, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 6),
            Row(
              children: [
                Radio<FeedRange>(
                    value: FeedRange.month,
                    groupValue: _range,
                    onChanged: (v) => _setRange(FeedRange.month)),
                Text(S.of(context)?.recentMonth ?? 'Recent Month',style: tt.bodySmall?.copyWith(color: cs.onSurface, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 6),
            Row(
              children: [
                Radio<FeedRange>(
                    value: FeedRange.quarter,
                    groupValue: _range,
                    onChanged: (v) => _setRange(FeedRange.quarter)),
                Text(S.of(context)?.recentQuarter ?? 'Recent Quarter',style: tt.bodySmall?.copyWith(color: cs.onSurface, fontSize: 12)),
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
                  child: Center(child: Text('Data loading failed: ${snap.error}')));
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
                    _buildLegendItem(Colors.blue.shade400,  S.of(context)?.breastMilk ?? "Breast Milk"),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.green.shade400, S.of(context)?.formula ?? "Formula"),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.orange.shade400, S.of(context)?.babyFood ?? "Baby Food"),
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
                      'Date: ${_selectedDay!.day.year}-${_selectedDay!.day.month}-${_selectedDay!.day.day}\nBreast Milk: ${_selectedDay!.milk.toInt()}ml, Formula: ${_selectedDay!.formula.toInt()}ml, Baby Food: ${_selectedDay!.babyFood.toInt()}g, 💩: ${_selectedDay!.poopCount} times',
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

class _DayStat {
  final DateTime day;
  double milk = 0;
  double formula = 0;
  double babyFood = 0; // g
  int poopCount = 0;

  _DayStat({required this.day});
}

class _AggDay {
  final List<_DayStat> series;
  final double maxMilkFormula;
  final double maxBabyFood;

  _AggDay(
      {required this.series,
        required this.maxMilkFormula,
        required this.maxBabyFood});
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