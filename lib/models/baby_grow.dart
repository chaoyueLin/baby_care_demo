

import '../common/db_constants.dart';

enum GrowType { weight, height}

extension FeedTypeExtension on GrowType {
  int get value => index;

  static GrowType fromInt(int value) {
    return GrowType.values[value];
  }
}

class BabyGrow {
  int? id;
  int babyId; // 关联 Baby 的 id
  int? date; // 时间戳（毫秒）
  GrowType type;
  String mush;

  BabyGrow({
    this.id,
    required this.babyId,
    required this.date,
    required this.type,
    required this.mush,
  });

  Map<String, dynamic> toMap() {
    return {
      columnGrowId: id,
      columnBabyId: babyId,
      columnDate: date,
      columnType: type.value,
      columnMush: mush,
    };
  }

  factory BabyGrow.fromMap(Map<dynamic, dynamic> map) {
    return BabyGrow(
      id: map[columnGrowId],
      babyId: map[columnBabyId],
      date: map[columnDate],
      type: FeedTypeExtension.fromInt(map[columnType]),
      mush: map[columnMush],
    );
  }
}
