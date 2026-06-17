
class User {
  List<String> chapterTops;
  List<int> collectIds;
  String email;
  String icon;
  int id;
  String password;
  String token;
  int type;
  String username;

  User(this.chapterTops, this.collectIds, thi1s.email, this.icon,
      this.id, this.password, this.token, this.type, this.username);

  factory User.fromJson(Map<String, dynamic> json) => User(
        (json['chapterTops'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        (json['collectIds'] as List<dynamic>? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        json['email'] as String? ?? '',
        json['icon'] as String? ?? '',
        (json['id'] as num?)?.toInt() ?? 0,
        json['password'] as String? ?? '',
        json['token'] as String? ?? '',
        (json['type'] as num?)?.toInt() ?? 0,
        json['username'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'chapterTops': chapterTops,
        'collectIds': collectIds,
        'email': email,
        'icon': icon,
        'id': id,
        'password': password,
        'token': token,
        'type': type,
        'username': username,
      };
}
