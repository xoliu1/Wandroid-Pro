import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/providers/pagination_provider.dart';

import '../model/article.dart';
import '../remote/Api.dart';
import '../remote/CgiArticle.dart';
import '../remote/service/NerworkService.dart';


///知识体系
final chapterProvider = FutureProvider<List<Chapter>>((ref) async {
  final chapters = await NetworkService.get<List<dynamic>>(
    url: URL_TREE,
  ).handleListData(Chapter.fromJson);
  return chapters;
});

class TreeArticleNotifier extends PaginationNotifier<Article> {
  TreeArticleNotifier({
    required this.cid,
    int? pageSize = 5,
  }) : super(
          fetchFunction: (page, size) async {
            final req = TreeArticleReq(cid: cid, page: page);
            return NetworkService.get<ArticleListResp>(
              url: req.path,
              fromJsonT: ArticleListResp.fromJson,
            ).getData().then((value) => value.datas);
          },
          defaultPageSize: pageSize,
        );

  final int cid;
}

///知识体系对应文章
final treeArticleProvider = StateNotifierProvider.family<TreeArticleNotifier,
    AsyncValue<List<Article>>, int>(
  (ref, cid) => TreeArticleNotifier(cid: cid),
);

final treeArticleProviderWithPageSize = StateNotifierProvider.family<
    TreeArticleNotifier, AsyncValue<List<Article>>, Map<String, dynamic>>(
  (ref, params) {
    final cid = params['cid'] as int;
    final pageSize = params['pageSize'] as int?;
    return TreeArticleNotifier(cid: cid, pageSize: pageSize);
  },
);

///导航
final naviProvider = FutureProvider<List<NaviItem>>((ref) async {
  return NetworkService.get<List<dynamic>>(
    url: URL_NAVI,
  ).handleListData(NaviItem.fromJson);
});


/// 广场文章分页provider
final squareArticleProvider = StateNotifierProvider<SquareArticleNotifier, AsyncValue<List<Article>>>((ref) {
  return SquareArticleNotifier(CgiArticle());
});


class SquareArticleNotifier extends PaginationNotifier<Article> {
  SquareArticleNotifier(this._articleService) : super(
    fetchFunction: (page, pageSize) async {
      return await _articleService.fetchSquareArticles(page, pageSize: pageSize);
    },
    defaultPageSize: 10,
    enableCache: true,
  );

  final CgiArticle _articleService;
}
