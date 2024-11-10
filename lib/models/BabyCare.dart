const String tableCare = 'babyCare';
const String columnCareId = '_id';
const String columnMilk = 'milk';
const String columnWater = 'water';
const String columnDefecate = 'defecate';

class BabyCare {
  int? id;
  int? milk;
  int? water;
  int? defecate;

  BabyCare({required this.id, required this.milk, required this.water, required this.defecate});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnMilk: milk,
      columnWater: water,
      columnDefecate: defecate
    };
    map[columnCareId] = id;
    return map;
  }

  BabyCare.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnCareId];
    milk = map[columnMilk];
    water = map[columnWater];
    defecate = map[columnDefecate];
  }
}
