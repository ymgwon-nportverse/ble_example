import 'dart:convert';

class Utils {
  static String typeConverter(List<int> value) {
    String convertedValue = utf8.decode(value);
    return convertedValue;
  }
}
