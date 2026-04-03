import '../model/Todo.dart';
import 'service/NerworkService.dart';

import 'Api.dart';

class CgiTodo {
  /// 新增一个 Todo
  /// [todo] 包含 title、content 等信息
  /// 返回新增后的 Todo 响应
  NetworkCall<AddTodoResp> addTodo(Todo todo) {
    final req = AddTodoReq(
      title: todo.title,
      content: todo.content,
      date: todo.dateStr.isNotEmpty ? todo.dateStr : null,
      type: todo.type > 0 ? todo.type : null,
      priority: todo.priority > 0 ? todo.priority : null,
    );
    return NetworkService.post<AddTodoResp>(
      url: URL_TODO_ADD,
      data: req.toJson(),
      fromJsonT: AddTodoResp.fromJson,
    );
  }

  /// 更新一个 Todo
  /// 注意：未携带的字段会被服务端默认值覆盖，务必传完整
  /// 当更新 status=1 时，服务端会自动设置当前时间为完成时间
  NetworkCall<AddTodoResp> updateTodo(Todo todo) {
    final req = UpdateTodoReq(
      id: todo.id,
      title: todo.title,
      content: todo.content,
      date: todo.dateStr,
      status: todo.status,
      type: todo.type,
      priority: todo.priority,
    );
    return NetworkService.post<AddTodoResp>(
      url: req.path,
      data: req.toJson(),
      fromJsonT: AddTodoResp.fromJson,
    );
  }

  /// 删除一个 Todo
  NetworkCall deleteTodo(int id) {
    final req = DeleteTodoReq(id: id);
    return NetworkService.post(
      url: req.path,
      data: {},
    );
  }

  /// 仅更新 Todo 完成状态
  /// [id] Todo 的唯一标识
  /// [status] 传 1 表示未完成→已完成，传 0 表示已完成→未完成
  NetworkCall<AddTodoResp> doneTodo(int id, int status) {
    final req = DoneTodoReq(id: id, status: status);
    return NetworkService.post<AddTodoResp>(
      url: req.path,
      data: req.toJson(),
      fromJsonT: AddTodoResp.fromJson,
    );
  }

  /// 查询 Todo 列表
  /// [page] 页码，从 1 开始
  /// [status] 状态筛选：0 未完成，1 已完成，不传则全部
  /// [type] 类型筛选：大于 0 的整数，不传则全部
  /// [priority] 优先级筛选：大于 0 的整数，不传则全部
  /// [orderby] 排序：1 完成日期顺序，2 完成日期逆序，3 创建日期顺序，4 创建日期逆序（默认）
  Future<List<Todo>> queryTodo(int page, {int? status, int? type, int? priority, int? orderby}) {
    final req = QueryTodoListReq(
      page: page,
      status: status,
      type: type,
      priority: priority,
      orderby: orderby,
    );
    return NetworkService.get<QueryTodoResp>(
      url: req.path,
      data: req.toQueryParams(),
      fromJsonT: QueryTodoResp.fromJson,
    ).handleData<List<Todo>>((data) => data.datas);
  }
}
