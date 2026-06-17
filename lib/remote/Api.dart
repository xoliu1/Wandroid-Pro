import '../model/Todo.dart';
import '../model/article.dart';
import '../model/project.dart';

/// 基础域名
const BASE_URL = 'https://wanandroid.com';

/// 注册接口
const URL_REGISTER = '/user/register';

/// 登录接口
const URL_LOGIN = '/user/login';

/// 用户信息接口
const URL_USER_INFO = '//user/lg/userinfo/json';

/// 退出登录接口
const URL_LOGOUT = '/user/logout/json';

/// 新增待办接口
const URL_TODO_ADD = '/lg/todo/add/json';

/// 更新待办接口（需拼接 id）
const URL_TODO_UPDATE = '/lg/todo/update';

/// 删除待办接口（需拼接 id）
const URL_TODO_DELETE = '/lg/todo/delete';

/// 仅更新完成状态接口（需拼接 id）
const URL_TODO_DONE = '/lg/todo/done';

/// 查询待办接口（需拼接页码）
const URL_TODO_QUERY = '/lg/todo/v2/list';

/// 文章列表接口
const URL_ARTICLE_LIST = '/article/list'; // 文章列表接口


/// 广场文章列表接口
const URL_SQUARE_ARTICLE_LIST = '/user_article/list'; // 广场文章列表接口

/// 问答列表接口
const URL_QUESTION_LIST = "/wenda/list/"; // 问答列表接口

/// banner接口
const URL_BANNER = '/banner/json'; // banner接口

/// 热搜接口
const URL_HOTKEY = '//hotkey/json'; // 热搜接口

/// 体系数据接口
const URL_TREE = '/tree/json'; // 体系数据

// 收藏相关接口
/// 收藏文章列表
const URL_COLLECT_LIST = '/lg/collect/list';

/// 收藏站内文章
const URL_COLLECT_ARTICLE = '/lg/collect';

/// 收藏站外文章
const URL_COLLECT_ADD = '/lg/collect/add/json';

/// 编辑收藏文章
const URL_COLLECT_UPDATE = '/lg/collect/user_article/update';

/// 搜索文章接口
const URL_ARTICLE_QUERY = '/article/query';

/// 公众号列表
const URL_WX_AUTHOR_LIST = '/wxarticle/chapters/json';

/// 公众号对应文章列表
const URL_WX_ARTICLE_LIST = '/wxarticle/list';

/// 导航列表
const URL_NAVI = '/navi/json';

/// 广场文章
const URL_USER_ARTICLE = '/user_article/list';

// 消息相关接口
const URL_MESSAGE_UNREAD_COUNT = '/message/lg/count_unread/json'; // 未读消息数量
const URL_MESSAGE_READED_LIST = '/message/lg/readed_list';  //已读/历史消息
const URL_MESSAGE_UNREAD_LIST = '/message/lg/unread_list';  // 未读消息


/// 教程
const  URL_TEACH_LIST = '/chapter/547/sublist/json';
///教程下所有文章列表: 复用URL_ARTICLE_LIST使用

/// 项目列表相关
const URL_PROJECT_LIST = '/article/listproject';

/// 积分排行榜
const URL_COIN_RANK = '/coin/rank';

/// user 积分详情
const URL_COIN_INFO = '/lg/coin/userinfo/json';

/// user积分历史
const URL_COIN_HISTORY = '//lg/coin/list/1/json';

final defaultUserInfo = UserInfoResp(
  coinInfo: CoinInfo(
    coinCount: 0,
    level: 0,
    nickname: '',
    rank: '',
    userId: 0,
    username: '',
  ),
  collectArticleInfo: CollectArticleInfo(count: 0),
  userInfo: UserInfo(
    admin: false,
    chapterTops: [],
    coinCount: 0,
    collectIds: [],
    email: '',
    icon: '',
    id: 0,
    nickname: '',
    password: '',
    publicName: '',
    token: '',
    type: 0,
    username: '',
  ),
);

class UserInfoResp {
  final CoinInfo coinInfo;
  final CollectArticleInfo collectArticleInfo;
  final UserInfo userInfo;

  UserInfoResp(
      {required this.coinInfo,
      required this.collectArticleInfo,
      required this.userInfo});

  factory UserInfoResp.fromJson(Map<String, dynamic> json) => UserInfoResp(
        coinInfo: CoinInfo.fromJson(json['coinInfo']),
        collectArticleInfo:
            CollectArticleInfo.fromJson(json['collectArticleInfo']),
        userInfo: UserInfo.fromJson(json['userInfo']),
      );

  Map<String, dynamic> toJson() => {
        'coinInfo': coinInfo.toJson(),
        'collectArticleInfo': collectArticleInfo.toJson(),
        'userInfo': userInfo.toJson(),
      };
}

class CollectArticleInfo {
  final int count;

  CollectArticleInfo({required this.count});

  factory CollectArticleInfo.fromJson(Map<String, dynamic> json) =>
      CollectArticleInfo(
        count: json['count'],
      );


  Map<String, dynamic> toJson() => {
        'count': count,
      };
}

class CoinInfo {
  final int coinCount; // 可用
  final int level; // 可用
  final String nickname;
  final String rank; // 可用
  final int userId; // 可用
  final String username; // 可用

  CoinInfo({
    required this.coinCount,
    required this.level,
    required this.nickname,
    required this.rank,
    required this.userId,
    required this.username,
  });

  factory CoinInfo.fromJson(Map<String, dynamic> json) => CoinInfo(
        coinCount: json['coinCount'],
        level: json['level'],
        nickname: json['nickname'],
        rank: json['rank'].toString(),
        userId: json['userId'],
        username: json['username'],
      );

  Map<String, dynamic> toJson() => {
        'coinCount': coinCount,
        'level': level,
        'nickname': nickname,
        'rank': rank,
        'userId': userId,
        'username': username,
      };
}

class UserInfo {
  final bool admin;
  final List<dynamic> chapterTops;
  final int coinCount; // 可用
  final List<int> collectIds; // 可用
  final String email; // 可用
  final String icon;
  final int id; // 可用
  final String nickname; // 可用
  final String password;
  final String publicName;
  final String token;
  final int type;
  final String username; // 可用

  UserInfo({
    required this.admin,
    required this.chapterTops,
    required this.coinCount,
    required this.collectIds,
    required this.email,
    required this.icon,
    required this.id,
    required this.nickname,
    required this.password,
    required this.publicName,
    required this.token,
    required this.type,
    required this.username,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        admin: json['admin'],
        chapterTops: List<dynamic>.from(json['chapterTops']),
        coinCount: json['coinCount'],
        collectIds: List<int>.from(json['collectIds']),
        email: json['email'],
        icon: json['icon'],
        id: json['id'],
        nickname: json['nickname'],
        password: json['password'],
        publicName: json['publicName'],
        token: json['token'],
        type: json['type'],
        username: json['username'],
      );

  Map<String, dynamic> toJson() => {
        'admin': admin,
        'chapterTops': chapterTops,
        'coinCount': coinCount,
        'collectIds': collectIds,
        'email': email,
        'icon': icon,
        'id': id,
        'nickname': nickname,
        'password': password,
        'publicName': publicName,
        'token': token,
        'type': type,
        'username': username,
      };
}

class AddTodoResp {
  final dynamic completeDate; // 完成日期时间戳，null表示未完成
  final String completeDateStr; // 完成日期字符串表示
  final String content; // 待办事项内容
  final int date; // 计划完成日期时间戳
  final String dateStr; // 计划完成日期字符串表示
  final int id; // 待办事项ID
  final int priority; // 优先级，0表示无优先级
  final int status; // 状态，0表示未完成
  final String title; // 待办事项标题
  final int type; // 待办事项类型，0表示无类型
  final int userId; // 用户ID

  AddTodoResp({
    required this.completeDate,
    required this.completeDateStr,
    required this.content,
    required this.date,
    required this.dateStr,
    required this.id,
    required this.priority,
    required this.status,
    required this.title,
    required this.type,
    required this.userId,
  });

  factory AddTodoResp.fromJson(Map<String, dynamic> json) => AddTodoResp(
        completeDate: json['completeDate'],
        completeDateStr: json['completeDateStr'] ?? '',
        content: json['content'] ?? '',
        date: json['date'] ?? 0,
        dateStr: json['dateStr'] ?? '',
        id: json['id'] ?? 0,
        priority: json['priority'] ?? 0,
        status: json['status'] ?? 0,
        title: json['title'] ?? '',
        type: json['type'] ?? 0,
        userId: json['userId'] ?? 0,
      );
}

/// 新增 Todo 请求
class AddTodoReq {
  final String title;
  final String content;
  final String? date;
  final int? type;
  final int? priority;

  AddTodoReq({
    required this.title,
    required this.content,
    this.date,
    this.type,
    this.priority,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    if (date != null) 'date': date,
    if (type != null && type! > 0) 'type': type,
    if (priority != null && priority! > 0) 'priority': priority,
  };
}

/// 更新 Todo 请求
/// 注意：未携带的字段会被服务端默认值覆盖，务必传完整
class UpdateTodoReq {
  final int id;
  final String title;
  final String content;
  final String date;
  final int status;
  final int type;
  final int priority;

  UpdateTodoReq({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.status = 0,
    this.type = 0,
    this.priority = 0,
  });

  String get path => '$URL_TODO_UPDATE/$id/json';

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'date': date,
    'status': status,
    'type': type,
    'priority': priority,
  };
}

/// 删除 Todo 请求
class DeleteTodoReq {
  final int id;

  DeleteTodoReq({required this.id});

  String get path => '$URL_TODO_DELETE/$id/json';
}

/// 仅更新 Todo 完成状态请求
/// status: 0 未完成 → 已完成，1 已完成 → 未完成
class DoneTodoReq {
  final int id;
  final int status;

  DoneTodoReq({required this.id, required this.status});

  String get path => '$URL_TODO_DONE/$id/json';

  Map<String, dynamic> toJson() => {
    'status': status,
  };
}

/// 查询 Todo 列表请求
class QueryTodoListReq {
  final int page;
  final int? status;
  final int? type;
  final int? priority;
  final int? orderby;

  QueryTodoListReq({
    required this.page,
    this.status,
    this.type,
    this.priority,
    this.orderby,
  });

  String get path => '$URL_TODO_QUERY/$page/json';

  Map<String, dynamic> toQueryParams() => {
    if (status != null) 'status': status,
    if (type != null && type! > 0) 'type': type,
    if (priority != null && priority! > 0) 'priority': priority,
    if (orderby != null) 'orderby': orderby,
  };
}

class QueryTodoResp {
  int curPage;
  List<Todo> datas;
  int offset;
  bool over;
  int pageCount;
  int size;
  int total;

  QueryTodoResp({
    required this.curPage,
    required this.datas,
    required this.offset,
    required this.over,
    required this.pageCount,
    required this.size,
    required this.total,
  });

  factory QueryTodoResp.fromJson(Map<String, dynamic> json) {
    return QueryTodoResp(
      curPage: json['curPage'],
      datas: (json['datas'] as List).map((e) => Todo.fromJson(e)).toList(),
      offset: json['offset'],
      over: json['over'],
      pageCount: json['pageCount'],
      size: json['size'],
      total: json['total'],
    );
  }
}

// 文章相关类
class ArticleListReq {
  final int page;
  final int? pageSize;

  ArticleListReq({
    required this.page,
    this.pageSize,
  });

  String get path {
    if (pageSize != null) {
      return '$URL_ARTICLE_LIST/$page/json?page_size=$pageSize';
    }
    return '$URL_ARTICLE_LIST/$page/json';
  }
}

class ArticleListResp {
  final int curPage;
  final List<Article> datas;
  final int offset;
  final bool over;
  final int pageCount;
  final int size;
  final int total;

  ArticleListResp({
    required this.curPage,
    required this.datas,
    required this.offset,
    required this.over,
    required this.pageCount,
    required this.size,
    required this.total,
  });

  factory ArticleListResp.fromJson(Map<String, dynamic> json) {
    return ArticleListResp(
      curPage: json['curPage'] ?? 0,
      datas:
          (json['datas'] as List?)?.map((e) => Article.fromJson(e)).toList() ??
              [],
      offset: json['offset'] ?? 0,
      over: json['over'] ?? false,
      pageCount: json['pageCount'] ?? 0,
      size: json['size'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

// 搜索文章请求类
class ArticleQueryReq {
  final int page;
  final String keyword;

  ArticleQueryReq({
    required this.page,
    required this.keyword,
  });

  String get path => '$URL_ARTICLE_QUERY/$page/json';

  Map<String, dynamic> toJson() => {
        'k': keyword,
      };
}

// banner相关类
class BannerResp {
  final List<BannerItem> data;

  BannerResp({required this.data});

  factory BannerResp.fromJson(Map<String, dynamic> json) {
    return BannerResp(
      data: (json['data'] as List).map((e) => BannerItem.fromJson(e)).toList(),
    );
  }
}

class BannerItem {
  final String desc;
  final int id;
  final String imagePath;
  final int isVisible;
  final int order;
  final String title;
  final int type;
  final String url;

  BannerItem({
    required this.desc,
    required this.id,
    required this.imagePath,
    required this.isVisible,
    required this.order,
    required this.title,
    required this.type,
    required this.url,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      desc: json['desc'] ?? '',
      id: json['id'] ?? 0,
      imagePath: json['imagePath'] ?? '',
      isVisible: json['isVisible'] ?? 0,
      order: json['order'] ?? 0,
      title: json['title'] ?? '',
      type: json['type'] ?? 0,
      url: json['url'] ?? '',
    );
  }
}


class SquareArticleListReq {
  final int page;
  final int? pageSize;

  SquareArticleListReq({
    required this.page,
    this.pageSize,
  });

  String get path {
    if (pageSize != null) {
      return '$URL_SQUARE_ARTICLE_LIST/$page/json?page_size=$pageSize';
    }
    return '$URL_SQUARE_ARTICLE_LIST/$page/json';
  }
}

class QuestionListReq {
  final int page;
  final int? pageSize;

  QuestionListReq({
    required this.page,
    this.pageSize,
  });


  String get path {
    if (pageSize != null) {
      return '$URL_QUESTION_LIST/$page/json?page_size=$pageSize';
    }
    return '$URL_QUESTION_LIST/$page/json';
  }
}


/// 收藏文章列表相关req
class CollectListReq {
  final int page;
  final int? pageSize;

  CollectListReq({
    required this.page,
    this.pageSize,
  });

  String get path {
    if (pageSize != null) {
      return '$URL_COLLECT_LIST/$page/json?page_size=$pageSize';
    }
    return '$URL_COLLECT_LIST/$page/json';
  }
}

/// 收藏文章列表 resp
class CollectListResp {
  final int curPage;
  final List<CollectArticle> datas;
  final int offset;
  final bool over;
  final int pageCount;
  final int size;
  final int total;

  CollectListResp({
    required this.curPage,
    required this.datas,
    required this.offset,
    required this.over,
    required this.pageCount,
    required this.size,
    required this.total,
  });


  factory CollectListResp.fromJson(Map<String, dynamic> json) {
    return CollectListResp(
      curPage: json['curPage'] as int,
      datas: (json['datas'] as List<dynamic>)
          .map((e) => CollectArticle.fromJson(e as Map<String, dynamic>))
          .toList(),
      offset: json['offset'] as int,
      over: json['over'] as bool,
      pageCount: json['pageCount'] as int,
      size: json['size'] as int,
      total: json['total'] as int,
    );
  }
}


class CollectArticle {
  final String author;
  final int chapterId;
  final String chapterName;
  final int courseId;
  final String desc;
  final String envelopePic;
  final int id;
  final String link;
  final String niceDate;
  final String origin;
  final int originId;
  final int publishTime;
  final String title;
  final int userId;
  final int visible;
  final int zan;

  CollectArticle({
    required this.author,
    required this.chapterId,
    required this.chapterName,
    required this.courseId,
    required this.desc,
    required this.envelopePic,
    required this.id,
    required this.link,
    required this.niceDate,
    required this.origin,
    required this.originId,
    required this.publishTime,
    required this.title,
    required this.userId,
    required this.visible,
    required this.zan,
  });


  factory CollectArticle.fromJson(Map<String, dynamic> json) {
    return CollectArticle(
      author: json['author'] as String,
      chapterId: json['chapterId'] as int,
      chapterName: json['chapterName'] as String,
      courseId: json['courseId'] as int,
      desc: json['desc'] as String,
      envelopePic: json['envelopePic'] as String,
      id: json['id'] as int,
      link: json['link'] as String,
      niceDate: json['niceDate'] as String,
      origin: json['origin'] as String,
      originId: json['originId'] as int,
      publishTime: json['publishTime'] as int,
      title: json['title'] as String,
      userId: json['userId'] as int,
      visible: json['visible'] as int,
      zan: json['zan'] as int,
    );
  }
}




// 收藏站内文章请求类
class CollectArticleReq {
  final int articleId;

  CollectArticleReq({
    required this.articleId,
  });

  String get path => '$URL_COLLECT_ARTICLE/$articleId/json';
}

// 收藏站外文章请求类
class CollectAddReq {
  final String title;
  final String author;
  final String link;

  CollectAddReq({
    required this.title,
    required this.author,
    required this.link,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'link': link,
      };
}

// 编辑收藏文章请求类
class CollectUpdateReq {
  final int id;
  final String title;
  final String link;
  final String author;

  CollectUpdateReq({
    required this.id,
    required this.title,
    required this.link,
    required this.author,
  });

  String get path => '$URL_COLLECT_UPDATE/$id/json';

  Map<String, dynamic> toJson() => {
        'title': title,
        'link': link,
        'author': author,
      };
}

// 热门搜索相关类
class HotKeyResp {
  final List<HotKeyItem> data;

  HotKeyResp({required this.data});

  factory HotKeyResp.fromJson(Map<String, dynamic> json) {
    return HotKeyResp(
      data: (json['data'] as List).map((e) => HotKeyItem.fromJson(e)).toList(),
    );
  }
}

class HotKeyItem {
  final int id;
  final String name;
  final String link;
  final int order;
  final int visible;

  HotKeyItem({
    required this.id,
    required this.name,
    required this.link,
    required this.order,
    required this.visible,
  });

  factory HotKeyItem.fromJson(Map<String, dynamic> json) {
    return HotKeyItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      link: json['link'] ?? '',
      order: json['order'] ?? 0,
      visible: json['visible'] ?? 0,
    );
  }
}

class ChapterResp {
  final List<Chapter> datas;

  ChapterResp({required this.datas});

  factory ChapterResp.fromJson(Map<String, dynamic> json) {
    print("ChapterResp: $json");
    return ChapterResp(
      datas: (json as List).map((e) => Chapter.fromJson(e)).toList(),
    );
  }
}

class Chapter {
  final List<dynamic> articleList;
  final String author;
  final List<Chapter> children; //子列表里的 name 是子名称
  final int courseId;
  final String cover;
  final String desc;

  // 查看该目录下所有文章
  final int id;
  final String lisense;
  final String lisenseLink;
  final String name; //名称
  final int order;
  final int parentChapterId;
  final int type;
  final bool userControlSetTop;
  final int visible;

  Chapter({
    required this.articleList,
    required this.author,
    required this.children,
    required this.courseId,
    required this.cover,
    required this.desc,
    required this.id,
    required this.lisense,
    required this.lisenseLink,
    required this.name,
    required this.order,
    required this.parentChapterId,
    required this.type,
    required this.userControlSetTop,
    required this.visible,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      articleList: json['articleList'] ?? [],
      author: json['author'] ?? '',
      children: (json['children'] as List?)
              ?.map((e) => Chapter.fromJson(e))
              .toList() ??
          [],
      courseId: json['courseId'] ?? 0,
      cover: json['cover'] ?? '',
      desc: json['desc'] ?? '',
      id: json['id'] ?? 0,
      lisense: json['lisense'] ?? '',
      lisenseLink: json['lisenseLink'] ?? '',
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      parentChapterId: json['parentChapterId'] ?? 0,
      type: json['type'] ?? 0,
      userControlSetTop: json['userControlSetTop'] ?? false,
      visible: json['visible'] ?? 0,
    );
  }
}

/// 体系相关
/// 也可用于教程文章
class TreeArticleReq {
  final int page;
  final int cid;

  TreeArticleReq({
    required this.page,
    required this.cid,
  });

  String get path => '$URL_ARTICLE_LIST/$page/json?cid=$cid';
}

class NaviItem {
  final List<Article> articles;
  final int cid;
  final String name;

  NaviItem({
    required this.articles,
    required this.cid,
    required this.name,
  });

  factory NaviItem.fromJson(Map<String, dynamic> json) {
    return NaviItem(
      articles: (json['articles'] as List<dynamic>?)
              ?.map((e) => Article.fromJson(e))
              .toList() ??
          [],
      cid: json['cid'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class ProjectResp {
  final List<Article> articleList;
  final String author;
  final List<ProjectResp> children;
  final int courseId;
  final String cover;
  final String desc;

  // 该id在获取该分类下项目时需要用到
  final int id;
  final String lisense;
  final String lisenseLink;

  // 该分类名称
  final String name;
  final int order;
  final int parentChapterId;
  final int type;
  final bool userControlSetTop;
  final int visible;

  ProjectResp({
    required this.articleList,
    required this.author,
    required this.children,
    required this.courseId,
    required this.cover,
    required this.desc,
    required this.id,
    required this.lisense,
    required this.lisenseLink,
    required this.name,
    required this.order,
    required this.parentChapterId,
    required this.type,
    required this.userControlSetTop,
    required this.visible,
  });

  factory ProjectResp.fromJson(Map<String, dynamic> json) {
    return ProjectResp(
      articleList: (json['articleList'] as List<dynamic>?)
              ?.map((e) => Article.fromJson(e))
              .toList() ??
          [],
      author: json['author'] ?? '',
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => ProjectResp.fromJson(e))
              .toList() ??
          [],
      courseId: json['courseId'] ?? 0,
      cover: json['cover'] ?? '',
      desc: json['desc'] ?? '',
      id: json['id'] ?? 0,
      lisense: json['lisense'] ?? '',
      lisenseLink: json['lisenseLink'] ?? '',
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      parentChapterId: json['parentChapterId'] ?? 0,
      type: json['type'] ?? 0,
      userControlSetTop: json['userControlSetTop'] ?? false,
      visible: json['visible'] ?? 1,
    );
  }
}

class UserArticleReq {
  final int page;
  final int? pageSize;

  UserArticleReq({
    required this.page,
    this.pageSize,
  });

  String get path {
    if (pageSize != null) {
      return '$URL_USER_ARTICLE/$page/json?page_size=$pageSize';
    }
    return '$URL_USER_ARTICLE/$page/json';
  }
}


// 消息列表请求类
class MessageListReq {
  final int page;
  final int? pageSize;

  MessageListReq({
    required this.page,
    this.pageSize,
  });

  String get path {
    if (pageSize != null) {
      return '$URL_MESSAGE_READED_LIST/$page/json?page_size=$pageSize';
    }
    return '$URL_MESSAGE_READED_LIST/$page/json';
  }
}

class UnreadMessageListReq {
  final int page;
  final int? pageSize;

  UnreadMessageListReq({
    required this.page,
    this.pageSize,
  });

  String get path {
    if (pageSize != null) {
      return '$URL_MESSAGE_UNREAD_LIST/$page/json?page_size=$pageSize';
    }
    return '$URL_MESSAGE_UNREAD_LIST/$page/json';
  }
}



class ProjectListReq {
  final int page;
  final int? pageSize;

  ProjectListReq({
    required this.page,
    this.pageSize,
  });

  String get path {
    if (pageSize != null) {
      return '$URL_PROJECT_LIST/$page/json?page_size=$pageSize';
    }
    return '$URL_PROJECT_LIST/$page/json';
  }
}

class ProjectListResp {
  final int curPage;
  final List<ProjectArticle> datas;
  final int offset;
  final bool over;
  final int pageCount;
  final int size;
  final int total;

  ProjectListResp({
    required this.curPage,
    required this.datas,
    required this.offset,
    required this.over,
    required this.pageCount,
    required this.size,
    required this.total,
  });

  factory ProjectListResp.fromJson(Map<String, dynamic> json) => ProjectListResp(
    curPage: json['curPage'] as int,
    datas: (json['datas'] as List<dynamic>?)?.map((e) => ProjectArticle.fromJson(e)).toList() ?? [],
    offset: json['offset'] as int,
    over: json['over'] as bool,
    pageCount: json['pageCount'] as int,
    size: json['size'] as int,
    total: json['total'] as int,
  );
}

/// 教材目录
class BookSection {
  final String author;
  final List<Article> children;
  final int courseId;
  final String cover;
  final String desc;
  /// id在获取单个教程下所有文章列表时会用到
  final int id;
  final String lisense;
  final String lisenseLink;
  final String name;
  final int order;
  final int parentChapterId;
  final bool userControlSetTop;
  final int visible;

  const BookSection({
    required this.author,
    required this.children,
    required this.courseId,
    required this.cover,
    required this.desc,
    required this.id,
    required this.lisense,
    required this.lisenseLink,
    required this.name,
    required this.order,
    required this.parentChapterId,
    required this.userControlSetTop,
    required this.visible,
  });

  factory BookSection.fromJson(Map<String, dynamic> json) => BookSection(
        author: json['author'] ?? '',
        children: (json['children'] as List? ?? [])
            .map((e) => Article.fromJson(e))
            .toList(),
        courseId: json['courseId'] ?? 0,
        cover: json['cover'] ?? '',
        desc: json['desc'] ?? '',
        id: json['id'] ?? 0,
        lisense: json['lisense'] ?? '',
        lisenseLink: json['lisenseLink'] ?? '',
        name: json['name'] ?? '',
        order: json['order'] ?? 0,
        parentChapterId: json['parentChapterId'] ?? 0,
        userControlSetTop: json['userControlSetTop'] ?? false,
        visible: json['visible'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'author': author,
        'children': children.map((e) => e.toJson()).toList(),
        'courseId': courseId,
        'cover': cover,
        'desc': desc,
        'id': id,
        'lisense': lisense,
        'lisenseLink': lisenseLink,
        'name': name,
        'order': order,
        'parentChapterId': parentChapterId,
        'userControlSetTop': userControlSetTop,
        'visible': visible,
      };
}

/// 公众号作者
class WxAuthorListResp {
  /// 文章列表 不用理解 一般都给空数据
  final List<dynamic> articleList;

  /// 作者
  final String author;

  /// 子分类 一般都给空数组
  final List<dynamic> children;

  /// 课程ID
  final int courseId;

  /// 封面
  final String cover;

  /// 描述
  final String desc;

  /// ID
  final int id;

  /// 许可证
  final String lisense;

  /// 许可证链接
  final String lisenseLink;

  /// 名称
  final String name;

  /// 排序
  final int order;

  /// 父章节ID，用于查询对应文章的列表
  final int parentChapterId;

  /// 类型
  final int type;

  /// 用户控制置顶
  final bool userControlSetTop;

  /// 可见性
  final int visible;

  WxAuthorListResp({
    required this.articleList,
    required this.author,
    required this.children,
    required this.courseId,
    required this.cover,
    required this.desc,
    required this.id,
    required this.lisense,
    required this.lisenseLink,
    required this.name,
    required this.order,
    required this.parentChapterId,
    required this.type,
    required this.userControlSetTop,
    required this.visible,
  });

  factory WxAuthorListResp.fromJson(Map<String, dynamic> json) {
    return WxAuthorListResp(
      articleList: json['articleList'] ?? [],
      author: json['author'] ?? '',
      children: json['children'] ?? [],
      courseId: json['courseId'] ?? 0,
      cover: json['cover'] ?? '',
      desc: json['desc'] ?? '',
      id: json['id'] ?? 0,
      lisense: json['lisense'] ?? '',
      lisenseLink: json['lisenseLink'] ?? '',
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      parentChapterId: json['parentChapterId'] ?? 0,
      type: json['type'] ?? 0,
      userControlSetTop: json['userControlSetTop'] ?? false,
      visible: json['visible'] ?? 1,
    );
  }
}

/// 公众号对应文章列表
class WxArticleListReq {
  final int id;
  final int page;
  final int? pageSize;

  WxArticleListReq({
    required this.id,
    required this.page,
    this.pageSize,
  });

  String get path {
    if (pageSize != null) {
      return '$URL_WX_ARTICLE_LIST/$id/$page/json?page_size=$pageSize';
    }
    return '$URL_WX_ARTICLE_LIST/$id/$page/json';
  }
}

/// 积分排行榜请求
class CoinRankReq {
  final int page;

  CoinRankReq({required this.page});

  String get path => '$URL_COIN_RANK/$page/json';
}

/// 积分排行榜响应
class CoinRankResp {
  final int curPage;
  final List<CoinRankItem> datas;
  final int offset;
  final bool over;
  final int pageCount;
  final int size;
  final int total;

  CoinRankResp({
    required this.curPage,
    required this.datas,
    required this.offset,
    required this.over,
    required this.pageCount,
    required this.size,
    required this.total,
  });

  factory CoinRankResp.fromJson(Map<String, dynamic> json) {
    return CoinRankResp(
      curPage: json['curPage'] ?? 0,
      datas: (json['datas'] as List?)?.map((e) => CoinRankItem.fromJson(e)).toList() ?? [],
      offset: json['offset'] ?? 0,
      over: json['over'] ?? false,
      pageCount: json['pageCount'] ?? 0,
      size: json['size'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

/// 积分排行榜单项
class CoinRankItem {
  final int coinCount;
  final int level;
  final String nickname;
  final String rank;
  final int userId;
  final String username;

  CoinRankItem({
    required this.coinCount,
    required this.level,
    required this.nickname,
    required this.rank,
    required this.userId,
    required this.username,
  });

  factory CoinRankItem.fromJson(Map<String, dynamic> json) {
    return CoinRankItem(
      coinCount: json['coinCount'] ?? 0,
      level: json['level'] ?? 0,
      nickname: json['nickname'] ?? '',
      rank: json['rank']?.toString() ?? '0',
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
    );
  }
}

/// 积分 Info
class UserCoinInfo {
  final int coinCount;
  final int level;
  final String nickname;
  final int rank;
  final int userId;
  final String username;

  UserCoinInfo({
    required this.coinCount,
    required this.level,
    required this.nickname,
    required this.rank,
    required this.userId,
    required this.username,
  });

  factory UserCoinInfo.fromJson(Map<String, dynamic> json) {
    // rank 字段在 JSON 中为字符串，需要手动转换为 int
    return UserCoinInfo(
      coinCount: json['coinCount'] as int,
      level: json['level'] as int,
      nickname: json['nickname'] as String? ?? '',
      rank: int.parse(json['rank'].toString()),
      userId: json['userId'] as int,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coinCount': coinCount,
      'level': level,
      'nickname': nickname,
      'rank': rank.toString(),
      'userId': userId,
      'username': username,
    };
  }
}


/// 个人积分 历史
class CoinHistory {
  int curPage;
  List<CoinHistoryItem> datas;
  int offset;
  bool over;
  int pageCount;
  int size;
  int total;

  CoinHistory({
    required this.curPage,
    required this.datas,
    required this.offset,
    required this.over,
    required this.pageCount,
    required this.size,
    required this.total,
  });

  factory CoinHistory.fromJson(Map<String, dynamic> json) {
    return CoinHistory(
      curPage: json['curPage'],
      datas: (json['datas'] as List).map((e) => CoinHistoryItem.fromJson(e)).toList(),
      offset: json['offset'],
      over: json['over'],
      pageCount: json['pageCount'],
      size: json['size'],
      total: json['total'],
    );
  }
}

class CoinHistoryItem{

  int coinCount;
  int date;
  String desc;
  int id;
  String reason;
  int type;
  int userId;
  String userName;

  CoinHistoryItem({
    required this.coinCount,
    required this.date,
    required this.desc,
    required this.id,
    required this.reason,
    required this.type,
    required this.userId,
    required this.userName,
  });

  factory CoinHistoryItem.fromJson(Map<String, dynamic> json) {
    return CoinHistoryItem(
      coinCount: json['coinCount'],
      date: json['date'],
      desc: json['desc'],
      id: json['id'],
      reason: json['reason'],
      type: json['type'],
      userId: json['userId'],
      userName: json['userName'],
    );
  }
}
