class DateUtils {
/// 将DateTime转换为"YYYY-MM-DD"格式的字符串
  String formatDateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

/// 将"YYYY-MM-DD"格式的字符串转换为DateTime
  DateTime string2Date(String dateStr) {
    return DateTime.parse(dateStr);
  }

/// 获取当前日期的"YYYY-MM-DD"格式字符串
  String getCurrentDateString() {
    return formatDateToString(DateTime.now());
  }

/// 比较两个日期字符串是否相同
  bool isSameDateString(String dateStr1, String dateStr2) {
    return dateStr1 == dateStr2;
  }

/// 检查日期字符串是否为有效格式
  bool isValidDateString(String dateStr) {
    try {
      string2Date(dateStr);
      return true;
    } catch (e) {
      return false;
    }
  }

/// 获取明天的日期字符串
  String getTomorrowDateString() {
    return formatDateToString(DateTime.now().add(const Duration(days: 1)));
  }

/// 获取昨天的日期字符串
  String getYesterdayDateString() {
    return formatDateToString(DateTime.now().subtract(const Duration(days: 1)));
  }

/// 计算两个日期字符串之间的天数差
  int daysBetweenDates(String dateStr1, String dateStr2) {
    final date1 = string2Date(dateStr1);
    final date2 = string2Date(dateStr2);
    return date2.difference(date1).inDays;
  }

/// 判断日期字符串是否在今天之前
  bool isBeforeToday(String dateStr) {
    return string2Date(dateStr).isBefore(DateTime.now());
  }

/// 判断日期字符串是否在今天之后
  bool isAfterToday(String dateStr) {
    return string2Date(dateStr).isAfter(DateTime.now());
  }
}
