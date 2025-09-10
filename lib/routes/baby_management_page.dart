import 'package:baby_care_demo/utils/date_util.dart';
import 'package:baby_care_demo/utils/toast_util.dart';
import 'package:flutter/material.dart';
import '../common/db_provider.dart';
import '../models/baby.dart';
import 'package:flutter_gen/gen_l10n/S.dart';

import '../utils/dialog_util.dart';
import 'baby_grow_page.dart';

class BabyManagementPage extends StatefulWidget {
  const BabyManagementPage({super.key});

  @override
  State<BabyManagementPage> createState() => _BabyManagementPageState();
}

class _BabyManagementPageState extends State<BabyManagementPage> {
  final DBProvider _dbProvider = DBProvider();
  List<Baby> _babies = [];
  bool _isLoading = true;
  bool _hasDeleted = false;

  @override
  void initState() {
    super.initState();
    _loadBabies();
  }

  Future<void> _loadBabies() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final babies = await _dbProvider.queryAllPersons();
      setState(() {
        _babies = babies ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastUtil.showToast('加载儿童列表失败: $e');
      }
    }
  }

  Future<void> _confirmDeleteBaby(Baby baby) async {
    final confirmed = await DialogUtil.showConfirmDialog(
      context,
      title: '确认删除',
      content: '确定要删除 "${baby.name ??
          '未命名'}" 吗？\n这将同时删除该儿童的所有相关数据。',
    );

    if (confirmed == true && mounted) {
      try {
        await _dbProvider.deletePerson(baby.id!);
        ToastUtil.showToast('删除成功');
        // 标记已删除
        _hasDeleted = true;
        // 重新加载
        await _loadBabies();

        // 如果删除后没有 baby 了，就清空栈并跳转
        if (_babies.isEmpty && mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/addBaby',
                (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        ToastUtil.showToast('删除失败: $e');
      }
    }
  }

  String _formatSex(Baby baby) {
    if (baby.sex == 1) {
      return 'M';
    }
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = Theme
        .of(context)
        .colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _hasDeleted);
          return false; // 阻止默认 pop，因为我们手动 pop 了
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('儿童信息管理'),
            backgroundColor: Theme
                .of(context)
                .appBarTheme
                .backgroundColor,
            foregroundColor: Theme
                .of(context)
                .appBarTheme
                .foregroundColor,
            elevation: 2,
          ),
          backgroundColor: cs.surface,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _babies.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.child_care_outlined,
                  size: 64,
                  color: cs.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无儿童数据',
                  style:
                  Theme
                      .of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadBabies,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _babies.length,
              itemBuilder: (context, index) {
                final baby = _babies[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: baby.sex == 1
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme
                            .of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Text(_formatSex(baby)),
                      ),
                    ),
                    title: Text(
                      baby.name ?? '未命名',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              size: 16,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                                '生日: ${DateUtil.dateToString(
                                    baby.birthdate) ??
                                    '未设置'}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              baby.show == 1
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 16,
                              color: baby.show == 1
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '状态: ${baby.show == 1 ? '显示' : '隐藏'}',
                              style: TextStyle(
                                color: baby.show == 1
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: baby.show == 1
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      onPressed: () => _confirmDeleteBaby(baby),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BabyGrowPage(baby: baby),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ));
  }
}
