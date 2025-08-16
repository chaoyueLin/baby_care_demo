import 'package:flutter/material.dart';
import '../common/db_provider.dart';
import '../models/baby.dart';
import 'daily_feeding_chart.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _HomePageState();
}

class _HomePageState extends State<SearchPage> {
  Baby? currentBaby;
  bool _loadingBaby = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentBabyAndData();
  }

  /// 获取当前 baby 并加载曲线数据（你之前的实现）
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
    } catch (_) {
      // 可选：打印或处理错误
    }
    await _refreshAll();
    setState(() => _loadingBaby = false);
  }

  Future<void> _refreshAll() async {
    // 如果需要刷新其他内容可放这里
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

    // 只渲染图表（不再显示宝宝信息行）
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          DailyFeedingChartAllInOne(
            babyId: currentBaby!.id!, // 确保 id 非 null
            // initialDay: DateTime.now(), // 可选
          ),
        ],
      ),
    );
  }
}
