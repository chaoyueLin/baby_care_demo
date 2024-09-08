const String tablePerson = 'person';
const String columnId = '_id';
const String columnName = 'name';
const String columnSex = 'sex';
const String columnAge = 'age';

class Person {
  int? id;
  String? name;
  String? sex;
  int? age;

  Person({required this.id, required this.name, required this.sex, required this.age});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnName: name,
      columnSex: sex,
      columnAge: age
    };
    map[columnId] = id;
    return map;
  }

  Person.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId];
    name = map[columnName];
    sex = map[columnSex];
    age = map[columnAge];
  }
}
