

import '../model/article.dart';
import 'Api.dart';
import 'service/NerworkService.dart';

class CgiArticle {
  ///首页拉文章
  Future<List<Article>> fetchArticles(int page, {int? pageSize}) {
    final req = ArticleListReq(page: page, pageSize: pageSize);
    return NetworkService.get<ArticleListResp>(
      url: req.path,
      fromJsonT: ArticleListResp.fromJson,
    ).getData().then((value)=>value.datas);
  }

  ///广场列表数据
  Future<List<Article>> fetchSquareArticles(int page, {int? pageSize}) {
    final req = SquareArticleListReq(page: page, pageSize: pageSize);
    return NetworkService.get<ArticleListResp>(
      url: req.path,
      fromJsonT: ArticleListResp.fromJson,
    ).getData().then((value)=>value.datas);
  }

  ///每日问答数据
  Future<List<Article>> fetchDailyQuestions(int page, {int? pageSize}) {
    final req = QuestionListReq(page: page, pageSize: pageSize);
    return NetworkService.get<ArticleListResp>(
      url: req.path,
      fromJsonT: ArticleListResp.fromJson,
    ).getData().then((value)=>value.datas);
  }

  ///文章搜索接口
  Future<List<Article>> searchArticles(int page, String keyword,
      {int? pageSize}) {
    final req = ArticleQueryReq(page: page, keyword: keyword);
    return NetworkService.post<ArticleListResp>(
      url: req.path,
      data: req.toJson(),
      fromJsonT: ArticleListResp.fromJson,
    ).getData().then((value)=>value.datas);
  }

  ///首页 banner
  Future<List<BannerItem>> fetchBanners() {
    return NetworkService.get(
      url: URL_BANNER,
    ).handleData<List<BannerItem>>(
      (data) {
        return (data as List<dynamic>)
            .map((json) => BannerItem.fromJson(json))
            .toList();
      },
      errorHandler: (errorCode, errorMsg) {
        throw Exception('Failed to fetch banners: $errorMsg');
      },
    );
  }

  ///搜索热词
  Future<List<HotKeyItem>> fetchHotKey() {
    return NetworkService.get(
      url: URL_HOTKEY,
    ).handleData<List<HotKeyItem>>(
      (data) {
        return (data as List<dynamic>)
            .map((json) => HotKeyItem.fromJson(json))
            .toList();
      },
      errorHandler: (errorCode, errorMsg) {
        throw Exception('Failed to fetch banners: $errorMsg');
      },
    );
  }

}

