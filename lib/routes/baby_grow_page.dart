import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
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

  // 加载生长数据
  Future<void> _loadGrows() async {
    try {
      setState(() => _isLoading = true);

      final grows = await _dbProvider.getGrowByBabyId(widget.baby.id!);

      _weightList = grows.where((g) => g.type == GrowType.weight).toList();
      _heightList = grows.where((g) => g.type == GrowType.height).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtil.showToast(
        S.of(context)?.loadGrowDataFailed(e.toString()) ??
            'Failed to load growth data: $e',
      );
    }
  }

  // 确认删除记录
  Future<void> _confirmDeleteGrow(BabyGrow grow) async {
    final confirmed = await DialogUtil.showConfirmDialog(
      context,
      title: S.of(context)?.confirmDelete ?? 'Confirm Delete',
      content: S.of(context)?.confirmDeleteGrow ??
          'Are you sure you want to delete this growth record?',
    );

    if (confirmed == true && mounted) {
      try {
        await _dbProvider.deleteGrow(grow.id!);
        ToastUtil.showToast(S.of(context)?.deleteSuccess ?? 'Deleted successfully');
        _loadGrows();
      } catch (e) {
        ToastUtil.showToast(
          S.of(context)?.deleteFailed(e.toString()) ?? 'Delete failed: $e',
        );
      }
    }
  }

  // 构建列表
  Widget _buildList(List<BabyGrow> list, String label, String noDataKey) {
    final cs = Theme.of(context).colorScheme;
    if (list.isEmpty) {
      return Center(
        child: Text(
          S.of(context)?.noGrowData(label) ?? 'No $label data',
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
                label == S.of(context)?.weight ? Icons.monitor_weight : Icons.height,
                color: cs.primary,
                size: 30,
              ),
              title: Text(
                '$label: ${grow.mush ?? "-"}',
              ),
              subtitle: Text('${DateUtil.msToDateString(grow.date)}'),
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
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.baby.name ?? (s?.unnamed ?? "Unnamed")} ${s?.growRecords ?? "Growth Records"}',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s?.weight ?? "Weight"),
            Tab(text: s?.height ?? "Height"),
          ],
        ),
      ),
      backgroundColor: cs.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList(_weightList, s?.weight ?? "Weight", "weight"),
          _buildList(_heightList, s?.height ?? "Height", "height"),
        ],
      ),
    );
  }
}
