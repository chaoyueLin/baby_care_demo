const String tablePerson = 'baby';
const String columnPersonId = '_id';
const String columnName = 'name';
const String columnSex = 'sex';
const String columnBirthdate = 'birthdate';

class Baby {
  int? id;
  String name;
  String sex;
  DateTime birthdate;

  Baby({this.id, required this.name, required this.sex, required this.birthdate});

  Map<String, dynamic> toMap() {
    return {
      columnPersonId: id,
      columnName: name,
      columnSex: sex,
      columnBirthdate: birthdate.millisecondsSinceEpoch, // Store as an integer
    };
  }

  Baby.fromMap(Map<String, dynamic> map)
      : id = map[columnPersonId] as int?,
        name = map[columnName] as String,
        sex = map[columnSex] as String,
        birthdate = DateTime.fromMillisecondsSinceEpoch(map[columnBirthdate] as int);
}
