import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_mode_notifier.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/ad_manager.dart';
import 'dart:io' show Platform;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currentVersion = '';
  String _appName = '';
  String _buildNumber = '';
  String _packageName = '';
  bool _isLoading = true;
  bool _isPurchasing = false;

  final AdManager _adManager = AdManager();

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _initAdManager();
  }

  Future<void> _initAdManager() async {
    await _adManager.init();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
        _appName = packageInfo.appName;
        _buildNumber = packageInfo.buildNumber;
        _packageName = packageInfo.packageName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentVersion = '1.0.1.101';
        _appName = 'App';
        _buildNumber = '101';
        _packageName = 'com.gracebaby.babycare';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePurchaseCoffee() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      final success = await _adManager.buyCoffee();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      S.of(context)?.purchaseSuccessful ??
                          'Thank you! You are now a premium member!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() {}); // 刷新界面以显示新状态
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context)?.purchaseFailed ??
                    'Purchase failed. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.purchaseError ??
                  'An error occurred during purchase.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  Future<void> _launchAppStore() async {
    try {
      String url;

      if (Platform.isAndroid) {
        // Android Play Store
        // 优先尝试打开Play Store应用
        url = 'market://details?id=$_packageName';

        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        } else {
          // 如果Play Store应用不可用，打开网页版
          url = 'https://play.google.com/store/apps/details?id=$_packageName';
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        }
      } else if (Platform.isIOS) {
        // iOS App Store
        // 注意：你需要将 YOUR_APP_ID 替换为你的实际App Store ID
        const appId = 'YOUR_APP_ID'; // 例如: '123456789'

        // 优先尝试打开App Store应用
        url = 'itms-apps://itunes.apple.com/app/id$appId';

        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        } else {
          // 如果App Store应用不可用，打开网页版
          url = 'https://apps.apple.com/app/id$appId';
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        }
      } else {
        // 其他平台（Web、Desktop等）
        throw UnsupportedError('Platform not supported');
      }

      // 显示检查更新提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(S.of(context)?.checkingUpdates ?? 'Checking for updates...'),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.updateError ?? 'Failed to open app store'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeModeNotifier>();
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Theme Section
          _buildSectionHeader(context, s?.theme ?? 'Theme'),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(s?.lightMode ?? 'Light Mode'),
                  subtitle: Text(s?.lightModeDescription ?? 'Always use light theme'),
                  value: ThemeMode.light,
                  groupValue: notifier.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      notifier.setMode(value);
                    }
                  },
                  secondary: Icon(
                    Icons.light_mode,
                    color: cs.primary,
                  ),
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: Text(s?.darkMode ?? 'Dark Mode'),
                  subtitle: Text(s?.darkModeDescription ?? 'Always use dark theme'),
                  value: ThemeMode.dark,
                  groupValue: notifier.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      notifier.setMode(value);
                    }
                  },
                  secondary: Icon(
                    Icons.dark_mode,
                    color: cs.primary,
                  ),
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: Text(s?.followSystem ?? 'Follow System'),
                  subtitle: Text(s?.followSystemDescription ?? 'Use device theme setting'),
                  value: ThemeMode.system,
                  groupValue: notifier.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      notifier.setMode(value);
                    }
                  },
                  secondary: Icon(
                    Icons.settings_suggest,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),

          // Current Status Info
          if (notifier.themeMode == ThemeMode.system) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: cs.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s?.currentTheme ?? 'Current Theme',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notifier.isDark
                              ? (s?.darkModeActive ?? 'Dark mode is active')
                              : (s?.lightModeActive ?? 'Light mode is active'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Premium Membership Section
          _buildSectionHeader(context, s?.premium ?? 'Premium'),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: _adManager.isCoffeeBought
                ? ListTile(
              title: Row(
                children: [
                  Text(s?.premiumMember ?? 'Premium Member'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s?.active ?? 'ACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                s?.premiumMemberDescription ??
                    'Thank you for supporting the developer! Enjoy ad-free experience.',
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
            )
                : ListTile(
              title: Text(s?.becomePremium ?? 'Become Premium Member'),
              subtitle: Text(
                s?.becomePremiumDescription ??
                    'Support the developer with a coffee and enjoy ad-free experience',
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_cafe,
                  color: cs.primary,
                ),
              ),
              trailing: _isPurchasing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(
                Icons.chevron_right,
                color: cs.primary,
              ),
              onTap: _isPurchasing ? null : _handlePurchaseCoffee,
            ),
          ),

          // About Section
          _buildSectionHeader(context, s?.about ?? 'About'),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(s?.about ?? 'About'),
              subtitle: Text(s?.checkForUpdates ?? 'Tap to check for updates'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'v$_currentVersion',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_buildNumber.isNotEmpty)
                          Text(
                            'Build $_buildNumber',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              leading: Icon(
                Icons.info_outline,
                color: cs.primary,
              ),
              onTap: _launchAppStore,
            ),
          ),

          // App Info Section (Additional info)
          if (!_isLoading && _appName.isNotEmpty) ...[
            _buildSectionHeader(context, s?.appInfo ?? 'App Information'),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(context, s?.appName ?? 'App Name', _appName),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, s?.version ?? 'Version', _currentVersion),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, s?.buildNumber ?? 'Build Number', _buildNumber),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, s?.packageName ?? 'Package Name', _packageName),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, s?.platform ?? 'Platform',
                        Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      s?.membershipStatus ?? 'Membership Status',
                      _adManager.isCoffeeBought
                          ? (s?.premium ?? 'Premium')
                          : (s?.free ?? 'Free'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}