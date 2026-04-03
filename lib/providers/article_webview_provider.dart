import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/models/article_content.dart';

/// WebView 文章内容状态
class ArticleWebViewState {
  final String url;
  final bool isLoading;
  final ArticleContent? content;
  final String? errorMessage;
  final double progress;
  
  const ArticleWebViewState({
    required this.url,
    this.isLoading = true,
    this.content,
    this.errorMessage,
    this.progress = 0.0,
  });
  
  ArticleWebViewState copyWith({
    String? url,
    bool? isLoading,
    ArticleContent? content,
    String? errorMessage,
    double? progress,
  }) {
    return ArticleWebViewState(
      url: url ?? this.url,
      isLoading: isLoading ?? this.isLoading,
      content: content ?? this.content,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}

/// WebView Provider
class ArticleWebViewNotifier extends StateNotifier<ArticleWebViewState> {
  ArticleWebViewNotifier(String url) : super(ArticleWebViewState(url: url));
  
  /// 更新加载进度
  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }
  
  /// 设置内容
  void setContent(ArticleContent content) {
    state = state.copyWith(
      content: content,
      isLoading: false,
      errorMessage: null,
    );
  }
  
  /// 设置错误
  void setError(String error) {
    state = state.copyWith(
      errorMessage: error,
      isLoading: false,
    );
  }
  
  /// 开始加载
  void startLoading() {
    state = state.copyWith(isLoading: true, errorMessage: null);
  }
  
  /// 完成加载
  void finishLoading() {
    state = state.copyWith(isLoading: false);
  }
}

/// Provider Factory
final articleWebViewProvider = StateNotifierProvider.family<
    ArticleWebViewNotifier, 
    ArticleWebViewState, 
    String
>((ref, url) {
  return ArticleWebViewNotifier(url);
});
