const String tablePerson = 'baby';
const String columnId = '_id';
const String columnName = 'name';
const String columnSex = 'sex';
const String columnAge = 'age';

class Baby {
  int? id;
  String? name;
  String? sex;
  int? age;

  Baby({required this.id, required this.name, required this.sex, required this.age});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnName: name,
      columnSex: sex,
      columnAge: age
    };
    map[columnId] = id;
    return map;
  }

  Baby.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId];
    name = map[columnName];
    sex = map[columnSex];
    age = map[columnAge];
  }
}
