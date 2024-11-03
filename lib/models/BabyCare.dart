const String tablePerson = 'babyCare';
const String columnId = '_id';
const String columnMilk = 'milk';
const String columnWater = 'water';
const String columnDefecate = 'defecate';

class Baby {
  int? id;
  int? milk;
  int? water;
  int? defecate;

  Baby({required this.id, required this.milk, required this.water, required this.defecate});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnMilk: milk,
      columnWater: water,
      columnDefecate: defecate
    };
    map[columnId] = id;
    return map;
  }

  Baby.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId];
    milk = map[columnMilk];
    water = map[columnWater];
    defecate = map[columnDefecate];
  }
}
