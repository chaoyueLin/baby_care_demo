import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isCoffeeBought = false;
  DateTime? _lastAdShownDate; // 记录上次广告展示日期

  // 初始化
  Future<void> init() async {
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.setup("your_revenuecat_api_key");

    await MobileAds.instance.initialize();
    await _checkCoffeePurchase();
    await _loadAdFrequencyData();
  }

  /// 加载广告频率控制数据
  Future<void> _loadAdFrequencyData() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastAdDateStr = prefs.getString('last_ad_shown_date');
    if (lastAdDateStr != null) {
      _lastAdShownDate = DateTime.tryParse(lastAdDateStr);
    }
  }

  /// 保存广告频率控制数据
  Future<void> _saveAdFrequencyData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastAdShownDate != null) {
      await prefs.setString('last_ad_shown_date', _lastAdShownDate!.toIso8601String());
    }
  }

  /// 检查是否已购买咖啡
  Future<void> _checkCoffeePurchase() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _isCoffeeBought = customerInfo.entitlements.active.containsKey('no_ads');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('coffee_bought', _isCoffeeBought);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      _isCoffeeBought = prefs.getBool('coffee_bought') ?? false;
    }
  }

  /// 购买咖啡
  Future<bool> buyCoffee() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return false;

      final pkg = current.availablePackages.firstWhere(
            (p) => p.identifier == "coffee_one_time",
      );

      if (pkg == null) return false;

      CustomerInfo customerInfo = await Purchases.purchasePackage(pkg);
      _isCoffeeBought = customerInfo.entitlements.active.containsKey('no_ads');

      if (_isCoffeeBought) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('coffee_bought', true);
      }

      return _isCoffeeBought;
    } catch (e) {
      print("购买咖啡失败: $e");
      return false;
    }
  }

  /// 检查是否可以显示广告
  bool _canShowAd() {
    if (_isCoffeeBought) return false;

    final today = DateTime.now();
    if (_lastAdShownDate != null) {
      final isSameDay = today.year == _lastAdShownDate!.year &&
          today.month == _lastAdShownDate!.month &&
          today.day == _lastAdShownDate!.day;
      if (isSameDay) return false; // 今天已经展示过
    }

    return true;
  }

  /// 加载插屏广告
  Future<void> loadInterstitialAd() async {
    if (_isCoffeeBought) return;

    try {
      await InterstitialAd.load(
        adUnitId: 'your_admob_interstitial_id',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print("广告加载失败: $error");
          },
        ),
      );
    } catch (e) {
      print("加载广告异常: $e");
    }
  }

  /// 显示插屏广告（每天最多一次）
  Future<void> showInterstitialAd() async {
    if (!_canShowAd()) {
      return;
    }

    // 记录今天已展示
    _lastAdShownDate = DateTime.now();
    await _saveAdFrequencyData();

    if (_interstitialAd != null && !_isCoffeeBought) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _interstitialAd = null;
        },
      );

      await _interstitialAd!.show();
    } else {
      loadInterstitialAd();
    }
  }

  bool get isCoffeeBought => _isCoffeeBought;
}
