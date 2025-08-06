const String tableCare = 'babyCare';
const String columnCareId = '_id';
const String columnDate = 'date';
const String columnType = 'type';
const String columnMush = 'mush';

enum FeedType { milk, formula, water,poop }

extension FeedTypeExtension on FeedType {
  int get value => index;

  static FeedType fromInt(int value) {
    return FeedType.values[value];
  }
}

class BabyCare {
  int? id;
  int? date; // 时间戳（毫秒）
  FeedType type;
  String mush;

  BabyCare({
    this.id,
    required this.date,
    required this.type,
    required this.mush,
  });

  Map<String, dynamic> toMap() {
    return {
      columnCareId: id,
      columnDate: date,
      columnType: type.value,
      columnMush: mush,
    };
  }

  factory BabyCare.fromMap(Map<dynamic, dynamic> map) {
    return BabyCare(
      id: map[columnCareId],
      date: map[columnDate],
      type: FeedTypeExtension.fromInt(map[columnType]),
      mush: map[columnMush],
    );
  }

  /// 是否为便便记录
  bool get isPoop => type == FeedType.poop;

  /// 便便记录的图片路径（如果是poop类型）
  List<String> get poopImages {
    if (!isPoop || mush.trim().isEmpty) return [];
    return mush.split(',').where((path) => path.isNotEmpty).toList();
  }
}
