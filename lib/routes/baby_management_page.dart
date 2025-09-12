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

  // 加载儿童列表
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
        ToastUtil.showToast(
          S.of(context)?.loadBabyListFailed(e.toString()) ??
              'Failed to load baby list: $e',
        );
      }
    }
  }

  // 确认删除儿童
  Future<void> _confirmDeleteBaby(Baby baby) async {
    final confirmed = await DialogUtil.showConfirmDialog(
      context,
      title: S.of(context)?.confirmDelete ?? 'Confirm Delete',
      content: S.of(context)?.confirmDeleteBaby(baby.name ?? (S.of(context)?.unnamed ?? 'Unnamed')) ??
          'Are you sure you want to delete "${baby.name ?? 'Unnamed'}"?\nThis will also delete all related data.',
    );

    if (confirmed == true && mounted) {
      try {
        await _dbProvider.deletePerson(baby.id!);
        ToastUtil.showToast(S.of(context)?.deleteSuccess ?? 'Deleted successfully');
        _hasDeleted = true;
        await _loadBabies();

        if (_babies.isEmpty && mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/addBaby',
                (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        ToastUtil.showToast(
          S.of(context)?.deleteFailed(e.toString()) ?? 'Delete failed: $e',
        );
      }
    }
  }

  // 格式化性别显示
  String _formatSex(Baby baby) {
    if (baby.sex == 1) {
      return S.of(context)?.maleShort ?? 'M';
    }
    return S.of(context)?.femaleShort ?? 'F';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasDeleted);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s?.babyManagement ?? 'Baby Management'),
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
                s?.noBabyData ?? 'No baby data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                          ? cs.primary.withOpacity(0.1)
                          : cs.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primaryContainer,
                      child: Text(_formatSex(baby)),
                    ),
                  ),
                  title: Text(
                    baby.name ?? (s?.unnamed ?? 'Unnamed'),
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
                            '${s?.birthday ?? "Birthday"}: ${DateUtil.dateToString(baby.birthdate)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            baby.show == 1 ? Icons.visibility : Icons.visibility_off,
                            size: 16,
                            color: baby.show == 1 ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${s?.status ?? "Status"}: ${baby.show == 1 ? (s?.visible ?? "Visible") : (s?.hidden ?? "Hidden")}',
                            style: TextStyle(
                              color: baby.show == 1 ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: baby.show == 1
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
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
      ),
    );
  }
}
