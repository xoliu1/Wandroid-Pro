

import 'package:freezed_annotation/freezed_annotation.dart';

part 'User.g.dart';

@JsonSerializable()
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

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

}