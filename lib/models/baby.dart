

import '../common/db_constants.dart';

class Baby {
  int? id;
  String name;
  int sex;
  DateTime birthdate; // 保持 DateTime 类型
  int show;

  Baby({
    this.id,
    required this.name,
    required this.sex,
    required this.birthdate,
    required this.show,
  });

  // 转换为 Map（数据库存储）
  Map<String, dynamic> toMap() {
    return {
      columnPersonId: id,
      columnName: name,
      columnSex: sex,
      columnBirthdate: birthdate.toIso8601String(), // 存储为字符串
      columnShow: show,
    };
  }

  // 从 Map 转换回来（数据库读取）
  factory Baby.fromMap(Map<String, dynamic> map) {
    return Baby(
      id: map[columnPersonId],
      name: map[columnName],
      sex: map[columnSex],
      birthdate: DateTime.parse(map[columnBirthdate]),
      show: map[columnShow],
    );
  }
}
