
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/local/KV.dart';
import 'package:wanandroid_pro/model/article.dart';
import 'package:wanandroid_pro/providers/pagination_provider.dart';

import '../remote/Api.dart';
import '../remote/CgiArticle.dart';
import '../remote/service/NerworkService.dart';

// 文章分页provider
final articleProvider = StateNotifierProvider<ArticleNotifier, AsyncValue<List<Article>>>((ref) {
  return ArticleNotifier(CgiArticle());
});

class ArticleNotifier extends PaginationNotifier<Article> {
  ArticleNotifier(this._articleService) : super(
    fetchFunction: (page, pageSize) async {
      return  await _articleService.fetchArticles(page, pageSize: pageSize);
      // return i.map((json) {return Article.fromJson(json);}).toList();
    },
    defaultPageSize: 10,
    enableCache: true,
  );

  final CgiArticle _articleService;
}

/// 搜索文章provider
final searchArticleProvider = StateNotifierProvider.family<SearchArticleNotifier, AsyncValue<List<Article>>, String>((ref, keyword) {
  return SearchArticleNotifier(CgiArticle(), keyword);
});
/// 搜索文章Notifier
class SearchArticleNotifier extends PaginationNotifier<Article> {
  SearchArticleNotifier(this._articleService, this.keyword) : super(
    fetchFunction: (page, pageSize) async {
      return await _articleService.searchArticles(page, keyword, pageSize: pageSize);
    },
    defaultPageSize: 10,
    enableCache: false, // 搜索不缓存
  );

  final CgiArticle _articleService;
  final String keyword;
}

/// banner provider
final bannerProvider = StateNotifierProvider<BannerNotifier, AsyncValue<List<BannerItem>>>((ref) {
  return BannerNotifier(CgiArticle());
});




/// 每日问答分页provider
final dailyQuestionProvider = StateNotifierProvider<DailyQuestionNotifier, AsyncValue<List<Article>>>((ref) {
  return DailyQuestionNotifier(CgiArticle());
});

class DailyQuestionNotifier extends PaginationNotifier<Article> {
  DailyQuestionNotifier(this._articleService) : super(
    fetchFunction: (page, pageSize) async {
      return await _articleService.fetchDailyQuestions(page, pageSize: pageSize);
    },
    defaultPageSize: 10,
    enableCache: true,
  );

  final CgiArticle _articleService;
}

class BannerNotifier extends StateNotifier<AsyncValue<List<BannerItem>>> {
  BannerNotifier(this._articleService) : super(const AsyncValue.loading()) {
    fetchBanners();
  }


  Future<void> fetchBanners() async {
    try {
      state = const AsyncValue.loading();
      final banners = await CgiArticle().fetchBanners();
      state = AsyncValue.data(banners);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> refresh() async {
    await fetchBanners();
  }
  final CgiArticle _articleService;

}




/// 教程目录列表
final teachListProvider = FutureProvider<List<BookSection>>((ref) async {
  return NetworkService.get(
    url: URL_TEACH_LIST,
  ).handleListData<BookSection>(BookSection.fromJson);
});



/// 教程对应文章列表
final teachArticleProvider = StateNotifierProvider.family<TeachArticleProvider, AsyncValue<List<Article>>, int>((ref, cid) {
  return TeachArticleProvider(cid: cid);
});

class TeachArticleProvider extends PaginationNotifier<Article> {
  TeachArticleProvider({
    required this.cid,
  }) : super(
    fetchFunction: (page, size) async {
      final req = TreeArticleReq(cid: cid, page: page);
      return NetworkService.get<ArticleListResp>(
        url: "${req.path}&order_type=1",
        ///注：这个接口是复用的章节，大多时候我们希望按照时间倒序，但是教程想要保持一个好的目录结构，需要正序，注意传入 order_type=1
        fromJsonT: ArticleListResp.fromJson,
      ).getData().then((value) => value.datas);
    },
    defaultPageSize: getPageSize(),
  );

  final int cid;
}