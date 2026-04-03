

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/providers/pagination_provider.dart';
import 'package:notes_app/remote/Api.dart';

import '../remote/service/NerworkService.dart';

/// 获取收藏列表
final collectArticleProvider = StateNotifierProvider<CollectListProvider, AsyncValue<List<CollectArticle>>>((ref) {
  return CollectListProvider();
});

class CollectListProvider extends PaginationNotifier<CollectArticle> {
  CollectListProvider() : super(
    fetchFunction: (page, pageSize) async {
      final req = CollectListReq(page: page, pageSize: pageSize);
      return NetworkService.get<CollectListResp>(
        url: req.path,
        fromJsonT: CollectListResp.fromJson,
      ).getData().then((data)=>data.datas);
    },
    defaultPageSize: 10,
    enableCache: true,
  );

  /// 从列表中移除指定 originId 的收藏文章（取消收藏后调用）
  void removeByOriginId(int originId) {
    final currentItems = items;
    currentItems.removeWhere((item) => item.originId == originId);
    state = AsyncValue.data(List.from(currentItems));
  }

  /// 从列表中移除指定 id 的收藏文章（取消收藏后调用）
  void removeById(int id) {
    final currentItems = items;
    currentItems.removeWhere((item) => item.id == id);
    state = AsyncValue.data(List.from(currentItems));
  }
}