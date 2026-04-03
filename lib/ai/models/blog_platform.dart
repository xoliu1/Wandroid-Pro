/// 博客平台枚举
enum BlogPlatform {
  /// CSDN
  csdn('CSDN', 'blog.csdn.net'),
  
  /// 掘金
  juejin('掘金', 'juejin.cn'),
  
  /// 微信公众号
  weixin('微信公众号', 'mp.weixin.qq.com'),
  
  /// 知乎专栏
  zhihu('知乎', 'zhuanlan.zhihu.com'),
  
  /// 简书
  jianshu('简书', 'jianshu.com'),
  
  /// SegmentFault
  segmentfault('思否', 'segmentfault.com'),
  
  /// WanAndroid
  wanandroid('玩Android', 'wanandroid.com'),
  
  /// 未知平台
  unknown('未知', '');
  
  final String displayName;
  final String domain;
  
  const BlogPlatform(this.displayName, this.domain);
  
  /// 从 URL 识别平台
  static BlogPlatform fromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return BlogPlatform.unknown;
    
    final host = uri.host.toLowerCase();
    
    for (final platform in BlogPlatform.values) {
      if (platform != BlogPlatform.unknown && host.contains(platform.domain)) {
        return platform;
      }
    }
    
    return BlogPlatform.unknown;
  }
}
