import 'package:intl/intl.dart';

class Todo {
  /// 任务ID
  final int id;
  /// 任务标题
  String title;
  /// 任务内容
  String content;
  /// 任务日期(时间戳)
  int date;
  /// 任务状态
  int status;
  /// 任务类型
  int type;
  /// 任务优先级
  int priority;
  /// 任务完成日期
  dynamic completeDate;
  /// 任务完成日期字符串
  String completeDateStr;
  /// 任务日期字符串格式
  String dateStr;
  int userId;

  Todo({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.status = 0,
    this.type = 0,
    this.priority = 0,
    this.completeDate,
    this.completeDateStr = "",
    this.dateStr = "",
    this.userId = 0,
  }) {
    dateStr = _formatDate(date);
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      date: json['date'] ?? 0,
      status: json['status'] ?? 0,
      type: json['type'] ?? 0,
      priority: json['priority'] ?? 0,
      completeDate: json['completeDate'],
      completeDateStr: json['completeDateStr'] ?? '',
      dateStr: json['dateStr'] ?? '',
      userId: json['userId'] ?? 0,
    )..dateStr = _formatDate(json['date'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'status': status,
      'type': type,
      'priority': priority,
      'completeDate': completeDate,
      'completeDateStr': completeDateStr,
      'dateStr': dateStr,
      'userId': userId,
    };
  }

  static String _formatDate(int timestamp) {
    return DateFormat('yyyy-MM-dd').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }

  Todo copyWith({
    int? id,
    String? title,
    String? content,
    int? date,
    int? status,
    int? type,
    int? priority,
    dynamic completeDate,
    String? completeDateStr,
    String? dateStr,
    int? userId,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      status: status ?? this.status,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      completeDate: completeDate ?? this.completeDate,
      completeDateStr: completeDateStr ?? this.completeDateStr,
      userId: userId ?? this.userId,
    )..dateStr = dateStr ?? _formatDate(date ?? this.date);
  }

  bool get isDone => status == 1;
  bool get isPending => status == 0;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date);

  @override
  String toString() {
    return 'Todo{id: $id, title: $title, content: $content, date: $date, status: $status, type: $type, priority: $priority, completeDate: $completeDate, completeDateStr: $completeDateStr, dateStr: $dateStr, userId: $userId}';
  }
}
