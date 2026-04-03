




import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'service/NerworkService.dart';

import 'Api.dart';

class CgiCollect {

  /// 收藏变更回调（全局注册，用于通知用户画像刷新等）
  static VoidCallback? onCollectChanged;

  // 收藏站内文章
  Future<bool> collectArticle(int articleId) async {
    final req = CollectArticleReq(articleId: articleId);
    final success = await NetworkService.post(
      url: req.path, data: FormData.fromMap({}),
    ).isSuccess();
    if (success) onCollectChanged?.call();
    return success;
  }

  // 收藏站外文章
  Future<bool> collectAdd(String title, String author, String link) async {
    final req = CollectAddReq(title: title, author: author, link: link);
    final success = await NetworkService.post(
      url: URL_COLLECT_ADD,
      data: FormData.fromMap(req.toJson()),
    ).isSuccess();
    if (success) onCollectChanged?.call();
    return success;
  }


  @Deprecated("有缺陷")
  Future<bool> updateCollectedArticle(int articleId, String title, String author, String link) async {
    final req = CollectUpdateReq(id: articleId, title: title, author: author, link: link);
    return NetworkService.post(
      url: req.path,
      data: FormData.fromMap(req.toJson()),
    ).isSuccess();
  }


  /// 取消收藏文章
  /// [isMyCollect] 是否来自"我的收藏"页面（自己录入的内容）
  /// [originId] 列表页下发的originId，仅在"我的收藏"页面有效；非"我的收藏"页面传-1
  /// !!目前仅用于列表页取消收藏
  Future<bool> uncollectArticle(int articleId, {bool isMyCollect = false, int originId = -1}) async {
    final url = isMyCollect
        ? '/lg/uncollect/$articleId/json'
        : '/lg/uncollect_originId/$articleId/json';
    final data = isMyCollect
        ? FormData.fromMap({'originId': originId})
        : FormData.fromMap({});
    final success = await NetworkService.post(
      url: url,
      data: data,
    ).isSuccess();
    if (success) onCollectChanged?.call();
    return success;
  }


}