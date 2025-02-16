import 'package:intl/intl.dart';

class DateUtil {
  // 日期转字符串
  static String dateToString(DateTime date, {String format = 'yyyy-MM-dd'}) {
    final DateFormat formatter = DateFormat(format);
    return formatter.format(date);
  }

  // 字符串转日期
  static DateTime stringToDate(String dateStr, {String format = 'yyyy-MM-dd'}) {
    final DateFormat formatter = DateFormat(format);
    return formatter.parse(dateStr);
  }
}
