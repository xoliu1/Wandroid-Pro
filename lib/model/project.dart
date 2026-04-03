
/// 项目文章数据模型
///
/// 对应玩 Android 项目列表接口返回的单条项目数据
class ProjectArticle {
  /// 是否由管理员添加
  final bool adminAdd;

  /// APK 下载链接（通常为空）
  final String apkLink;

  /// 审核状态：1 表示已审核
  final int audit;

  /// 作者名称
  final String author;

  /// 当前用户是否有编辑权限
  final bool canEdit;

  /// 所属章节 ID
  final int chapterId;

  /// 章节名称
  final String chapterName;

  /// 是否已收藏（可动态修改）
  bool collect;

  /// 课程 ID
  final int courseId;

  /// 项目描述
  final String desc;

  /// 项目描述（Markdown 格式，可能为空）
  final String descMd;

  /// 封面图 URL
  final String envelopePic;

  /// 是否为最新
  final bool fresh;

  /// 主机地址（通常为空）
  final String host;

  /// 文章/项目 ID
  final int id;

  /// 是否由管理员添加（与 adminAdd 含义相同）
  final bool isAdminAdd;

  /// 文章详情链接
  final String link;

  /// 格式化后的发布时间
  final String niceDate;

  /// 格式化后的分享时间
  final String niceShareDate;

  /// 来源（通常为空）
  final String origin;

  /// 前缀（通常为空）
  final String prefix;

  /// 项目 GitHub 链接
  final String projectLink;

  /// 发布时间（毫秒时间戳）
  final int publishTime;

  /// 真实父章节 ID
  final int realSuperChapterId;

  /// 可见性：0 表示所有人可见
  final int selfVisible;

  /// 分享时间（毫秒时间戳）
  final int shareDate;

  /// 分享人用户名（为空表示作者本人）
  final String shareUser;

  /// 父章节 ID
  final int superChapterId;

  /// 父章节名称
  final String superChapterName;

  /// 标签列表
  final List<ProjectTag> tags;

  /// 文章标题
  final String title;

  /// 类型：0 表示普通文章
  final int type;

  /// 用户 ID（-1 表示未登录）
  final int userId;

  /// 可见性：1 表示可见
  final int visible;

  /// 点赞数
  final int zan;

  ProjectArticle({
    required this.adminAdd,
    required this.apkLink,
    required this.audit,
    required this.author,
    required this.canEdit,
    required this.chapterId,
    required this.chapterName,
    required this.collect,
    required this.courseId,
    required this.desc,
    required this.descMd,
    required this.envelopePic,
    required this.fresh,
    required this.host,
    required this.id,
    required this.isAdminAdd,
    required this.link,
    required this.niceDate,
    required this.niceShareDate,
    required this.origin,
    required this.prefix,
    required this.projectLink,
    required this.publishTime,
    required this.realSuperChapterId,
    required this.selfVisible,
    required this.shareDate,
    required this.shareUser,
    required this.superChapterId,
    required this.superChapterName,
    required this.tags,
    required this.title,
    required this.type,
    required this.userId,
    required this.visible,
    required this.zan,
  });

  /// 从 JSON 创建 ProjectArticle 实例
  factory ProjectArticle.fromJson(Map<String, dynamic> json) {
    return ProjectArticle(
      adminAdd: json['adminAdd'] as bool,
      apkLink: json['apkLink'] as String,
      audit: json['audit'] as int,
      author: json['author'] as String,
      canEdit: json['canEdit'] as bool,
      chapterId: json['chapterId'] as int,
      chapterName: json['chapterName'] as String,
      collect: json['collect'] as bool,
      courseId: json['courseId'] as int,
      desc: json['desc'] as String,
      descMd: json['descMd'] as String,
      envelopePic: json['envelopePic'] as String,
      fresh: json['fresh'] as bool,
      host: json['host'] as String,
      id: json['id'] as int,
      isAdminAdd: json['isAdminAdd'] as bool,
      link: json['link'] as String,
      niceDate: json['niceDate'] as String,
      niceShareDate: json['niceShareDate'] as String,
      origin: json['origin'] as String,
      prefix: json['prefix'] as String,
      projectLink: json['projectLink'] as String,
      publishTime: json['publishTime'] as int,
      realSuperChapterId: json['realSuperChapterId'] as int,
      selfVisible: json['selfVisible'] as int,
      shareDate: json['shareDate'] as int,
      shareUser: json['shareUser'] as String,
      superChapterId: json['superChapterId'] as int,
      superChapterName: json['superChapterName'] as String,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => ProjectTag.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      title: json['title'] as String,
      type: json['type'] as int,
      userId: json['userId'] as int,
      visible: json['visible'] as int,
      zan: json['zan'] as int,
    );
  }

  /// 将 ProjectArticle 实例转为 JSON
  Map<String, dynamic> toJson() {
    return {
      'adminAdd': adminAdd,
      'apkLink': apkLink,
      'audit': audit,
      'author': author,
      'canEdit': canEdit,
      'chapterId': chapterId,
      'chapterName': chapterName,
      'collect': collect,
      'courseId': courseId,
      'desc': desc,
      'descMd': descMd,
      'envelopePic': envelopePic,
      'fresh': fresh,
      'host': host,
      'id': id,
      'isAdminAdd': isAdminAdd,
      'link': link,
      'niceDate': niceDate,
      'niceShareDate': niceShareDate,
      'origin': origin,
      'prefix': prefix,
      'projectLink': projectLink,
      'publishTime': publishTime,
      'realSuperChapterId': realSuperChapterId,
      'selfVisible': selfVisible,
      'shareDate': shareDate,
      'shareUser': shareUser,
      'superChapterId': superChapterId,
      'superChapterName': superChapterName,
      'tags': tags.map((e) => e.toJson()).toList(),
      'title': title,
      'type': type,
      'userId': userId,
      'visible': visible,
      'zan': zan,
    };
  }
}

/// 项目标签数据模型
class ProjectTag {
  /// 标签名称
  final String name;

  /// 标签链接
  final String url;

  const ProjectTag({
    required this.name,
    required this.url,
  });

  /// 从 JSON 创建 ProjectTag 实例
  factory ProjectTag.fromJson(Map<String, dynamic> json) {
    return ProjectTag(
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }

  /// 将 ProjectTag 实例转为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}

