// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'User.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      (json['chapterTops'] as List<dynamic>).map((e) => e as String).toList(),
      (json['collectIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      json['email'] as String,
      json['icon'] as String,
      (json['id'] as num).toInt(),
      json['password'] as String,
      json['token'] as String,
      (json['type'] as num).toInt(),
      json['username'] as String,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'chapterTops': instance.chapterTops,
      'collectIds': instance.collectIds,
      'email': instance.email,
      'icon': instance.icon,
      'id': instance.id,
      'password': instance.password,
      'token': instance.token,
      'type': instance.type,
      'username': instance.username,
    };
