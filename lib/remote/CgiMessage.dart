import '../model/message.dart';
import 'Api.dart';
import 'service/NerworkService.dart';

class CgiMessage {
  // 获取未读消息数量
  Future<int> getUnreadCount() {
    return NetworkService.get(
      url: URL_MESSAGE_UNREAD_COUNT,
    ).handleData<int>(
      (data) {
        return data as int;
      },
      errorHandler: (errorCode, errorMsg) {
        throw Exception('Failed to get unread count: $errorMsg');
      },
    );
  }

  // 获取已读消息列表
  Future<List<Message>> getReadedMessages(int page, {int? pageSize}) {
    final req = MessageListReq(page: page, pageSize: pageSize);
    return NetworkService.get<MessageListResp>(
      url: req.path,
      fromJsonT: MessageListResp.fromJson,
    ).getData().then((value) => value.datas);
  }

  // 获取未读消息列表
  Future<List<Message>> getUnreadMessages(int page, {int? pageSize}) {
    final req = UnreadMessageListReq(page: page, pageSize: pageSize);
    return NetworkService.get<MessageListResp>(
      url: req.path,
      fromJsonT: MessageListResp.fromJson,
    ).getData().then((value) => value.datas);
  }
}