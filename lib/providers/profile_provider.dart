
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/remote/Api.dart';
import 'package:wanandroid_pro/remote/service/NerworkService.dart';
import '../local/KV.dart';
import '../model/message.dart';
import '../providers/pagination_provider.dart';
import '../remote/CgiMessage.dart';

final cgiMessage = CgiMessage();

/// 登录状态 Provider
/// 
/// 使用 StateNotifierProvider 管理全局登录状态，避免每次都调用 isLogin()
/// 任何需要根据登录状态做 UI 变化的地方，都应该 watch 这个 Provider
final loginStateProvider = StateNotifierProvider<LoginStateNotifier, bool>((ref) {
  return LoginStateNotifier();
});

class LoginStateNotifier extends StateNotifier<bool> {
  LoginStateNotifier() : super(isLogin());

  /// 更新登录状态
  void updateLoginState(bool isLoggedIn) {
    state = isLoggedIn;
  }

  /// 退出登录
  void logout() {
    state = false;
  }

  /// 登录成功
  void login() {
    state = true;
  }
}

/// 未读消息数量
final unreadMessageCountProvider =
    StateNotifierProvider<UnreadMessageCountNotifier, int>((ref) {
  return UnreadMessageCountNotifier(cgiMessage);
});

class UnreadMessageCountNotifier extends StateNotifier<int> {
  final CgiMessage _cgiMessage;

  UnreadMessageCountNotifier(this._cgiMessage) : super(0) {
    loadUnreadCount();
  }

  Future<void> loadUnreadCount() async {
    try {
      state = await _cgiMessage.getUnreadCount();
    } catch (e) {
      state = 0;
    }
  }

  /// 无用
  void markAllRead() {
    state = 0;
  }
}

/// 未读消息列表 - 使用PaginationNotifier
final unreadMessagesProvider =
    StateNotifierProvider<UnreadMessagesNotifier, AsyncValue<List<Message>>>((ref) {
  return UnreadMessagesNotifier(cgiMessage);
});

class UnreadMessagesNotifier extends PaginationNotifier<Message> {
  final CgiMessage _cgiMessage;

  UnreadMessagesNotifier(this._cgiMessage) : super(
    fetchFunction: (page, pageSize) async {
      return await _cgiMessage.getUnreadMessages(page + 1, pageSize: pageSize);
    },
    defaultPageSize: 5,
    enableCache: false, // 未读消息不缓存，因为访问后会变为已读
  );
}

/// 已读消息列表 - 使用PaginationNotifier
final readedMessagesProvider =
    StateNotifierProvider<ReadedMessagesNotifier, AsyncValue<List<Message>>>((ref) {
  return ReadedMessagesNotifier(cgiMessage);
});

class ReadedMessagesNotifier extends PaginationNotifier<Message> {
  final CgiMessage _cgiMessage;

  ReadedMessagesNotifier(this._cgiMessage) : super(
    fetchFunction: (page, pageSize) async {
      return await _cgiMessage.getReadedMessages(page + 1, pageSize: pageSize);
    },
    defaultPageSize: 10,
    enableCache: true,
  );
}

// 很多简单的就不分层了，直接 provider 请求
/// 积分
final coinInfoProvider = FutureProvider.autoDispose((ref) async{
  final coinInfo = await NetworkService.get<UserCoinInfo>(url: URL_COIN_INFO, fromJsonT: UserCoinInfo.fromJson).getData();
  return  coinInfo;
});

/// 积分历史
final coinHistoryProvider = FutureProvider.autoDispose((ref) async{
  return await NetworkService.get<CoinHistory>(url: URL_COIN_HISTORY, fromJsonT: CoinHistory.fromJson).getData();
});

/// 积分排行榜
final coinRankProvider =
    StateNotifierProvider<CoinRankNotifier, AsyncValue<List<CoinRankItem>>>((ref) {
  return CoinRankNotifier();
});

class CoinRankNotifier extends PaginationNotifier<CoinRankItem> {
  CoinRankNotifier() : super(
    fetchFunction: (page, pageSize) async {
      // 排行榜接口页码从 1 开始
      final req = CoinRankReq(page: page + 1);
      final resp = await NetworkService.get<CoinRankResp>(
        url: req.path,
        fromJsonT: CoinRankResp.fromJson,
      ).getData();
      return resp.datas;
    },
    enableCache: true,
  );
}
