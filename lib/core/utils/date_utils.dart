class DateFormatUtils {
  static String formatDateTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr);
      return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      if (dtStr.length >= 16) return dtStr.substring(0, 16);
      return dtStr;
    }
  }

  static String formatDateOnly(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr);
      return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}";
    } catch (e) {
      if (dtStr.length >= 10) return dtStr.substring(0, 10);
      return dtStr;
    }
  }
}
