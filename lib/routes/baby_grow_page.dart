import 'package:flutter/material.dart';
import '../common/db_provider.dart';
import '../models/baby.dart';
import '../models/baby_grow.dart';
import '../utils/date_util.dart';
import '../utils/toast_util.dart';
import '../utils/dialog_util.dart';

class BabyGrowPage extends StatefulWidget {
  final Baby baby;

  const BabyGrowPage({super.key, required this.baby});

  @override
  State<BabyGrowPage> createState() => _BabyGrowPageState();
}

class _BabyGrowPageState extends State<BabyGrowPage>
    with SingleTickerProviderStateMixin {
  final DBProvider _dbProvider = DBProvider();
  List<BabyGrow> _weightList = [];
  List<BabyGrow> _heightList = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGrows();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGrows() async {
    try {
      setState(() => _isLoading = true);

      final grows = await _dbProvider.getGrowByBabyId(widget.baby.id!);

      // 简单区分：type=0 体重，type=1 身高
      _weightList = grows.where((g) => g.type == GrowType.weight).toList();
      _heightList = grows.where((g) => g.type == GrowType.height).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtil.showToast('加载生长数据失败: $e');
    }
  }

  Future<void> _confirmDeleteGrow(BabyGrow grow) async {
    final confirmed = await DialogUtil.showConfirmDialog(
      context,
      title: '确认删除',
      content: '确定要删除这条生长记录吗？',
    );

    if (confirmed == true && mounted) {
      try {
        await _dbProvider.deleteGrow(grow.id!);
        ToastUtil.showToast('删除成功');
        _loadGrows();
      } catch (e) {
        ToastUtil.showToast('删除失败: $e');
      }
    }
  }

  Widget _buildList(List<BabyGrow> list, String label) {
    final cs = Theme.of(context).colorScheme;
    if (list.isEmpty) {
      return Center(
        child: Text(
          '暂无$label数据',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: cs.onSurface.withOpacity(0.5)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGrows,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final grow = list[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(
                label == "体重" ? Icons.monitor_weight : Icons.height,
                color: cs.primary,
                size: 30,
              ),
              title: Text(
                '$label: ${grow.mush ?? "-"}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                  '日期: ${DateUtil.msToDateString(grow.date) ?? "未知"}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteGrow(grow),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.baby.name ?? "未命名"} 的生长记录'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "体重"),
            Tab(text: "身高"),
          ],
        ),
      ),
      backgroundColor: cs.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList(_weightList, "体重"),
          _buildList(_heightList, "身高"),
        ],
      ),
    );
  }
}
