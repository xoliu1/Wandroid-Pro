


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/providers/pagination_provider.dart';
import 'package:wanandroid_pro/remote/Api.dart';

import '../local/KV.dart';
import '../model/project.dart';
import '../remote/service/NerworkService.dart';

/// 微信公众号列表
final wxAuthorProvider = FutureProvider<List<WxAuthorListResp>>((ref) async {
  return NetworkService.get(
    url: URL_WX_AUTHOR_LIST,
  ).handleListData<WxAuthorListResp>(WxAuthorListResp.fromJson);
});



/// 微信公众号对应文章列表
final wxArticleProvider = StateNotifierProvider.family<WxArticleProvider, AsyncValue<List<ProjectArticle>>, int>((ref, id) {
  return WxArticleProvider(id: id);
});

class WxArticleProvider extends PaginationNotifier<ProjectArticle> {
  WxArticleProvider({
    required this.id,
  }) : super(
    fetchFunction: (page, size) async {
      final req = WxArticleListReq(id: id, page: page, pageSize: size);
      return NetworkService.get<ProjectListResp>(
        url: req.path,
        fromJsonT: ProjectListResp.fromJson,
      ).getData().then((value) => value.datas);
    },
    defaultPageSize: getPageSize(),
  );

  final int id;
}