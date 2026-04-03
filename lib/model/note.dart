class Note {
  String id;
  String content;
  DateTime date;
  DateTime lastModified;

  Note({
    required this.id,
    required this.content,
    required this.date,
    required this.lastModified,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      content: map['content'] is String ? map['content'] : '',
      date: DateTime.parse(map['date']),
      lastModified: DateTime.parse(map['lastModified']),
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'date': date.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  Note copyWith({
    String? id,
    String? content,
    DateTime? date,
    DateTime? lastModified,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      date: date ?? this.date,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
final tempNote = Note(
  id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
  content: '临时笔记内容',
  date: DateTime.now(),
  lastModified: DateTime.now(),
);

