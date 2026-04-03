import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/drawer/todo/todo_entry.dart';
import '../../ai/ui/ai_provider_management_page.dart';
import 'ai_daily_report_sheet.dart';
import 'browsing_history_page.dart';
import 'chat_history_page.dart';

import '../../local/KV.dart';
import '../../providers/profile_provider.dart';
import '../../remote/CgiUser.dart';
import '../../utils/platform_utils.dart';
import '../../utils/theme.dart';
import '../coin/coin_page.dart';
import '../coin/coin_rank_page.dart';
import '../collect/collect_list_page.dart';
import '../login/login_page.dart';
import 'message/message_page.dart';
import 'note/notes.dart';
import '../settings/settings_page.dart';

/// 主页 - 文章列表抽屉
class HomeSlider extends ConsumerWidget {
  const HomeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 ref.watch 监听登录状态，当状态变化时 UI 会自动重建
    final isLoggedIn = ref.watch(loginStateProvider);
    
    return Scaffold(
        backgroundColor: context.surfaceColor,  // 统一背景色
        body: SafeArea(
            child: Column(children: [
              _buildProfile(context, isLoggedIn),
              Expanded(child: _buildConfig(context, ref, isLoggedIn)),
            ])));
  }

  /// 头像、姓名、等级、排名
  Widget _buildProfile(BuildContext context, bool isLoggedIn) {
    final colorS = Theme.of(context).colorScheme;
    
    if (!isLoggedIn) {
      // 未登录状态
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(
            bottom: BorderSide(
              color: context.dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: colorS.primaryContainer,
              child: Icon(
                CupertinoIcons.person,
                size: 40,
                color: colorS.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '未登录',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorS.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '登录后可使用更多功能',
              style: TextStyle(
                fontSize: 14,
                color: colorS.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    // 已登录状态
    final profile = getUserProfile();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: CachedNetworkImageProvider(profile
                    .userInfo.icon.isNotEmpty
                ? profile.userInfo.icon
                : "https://avatars.githubusercontent.com/u/126433098"),
          ),
          const SizedBox(height: 12),
          Text(
            profile.userInfo.publicName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorS.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            profile.userInfo.email.isNotEmpty
                ? profile.userInfo.email
                : '未绑定邮箱',
            style: TextStyle(
              fontSize: 13,
              color: colorS.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '等级 Lv.${profile.coinInfo.level}  |  排名 ${profile.coinInfo.rank}',
            style: TextStyle(
              fontSize: 13,
              color: colorS.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfig(BuildContext context, WidgetRef ref, bool isLoggedIn) {
    return Container(
      color: context.surfaceColor,
      child: ListView(
        padding: EdgeInsets.zero,  // 移除默认 padding
        children: [
          const SizedBox(height: 8),  // 顶部小间距
          // 第一组：通知、TODO、NOTE（仅登录时显示）
          if (isLoggedIn) ...[
            if (PlatformUtils.isAndroid)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  '个人中心',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.secondaryTextColor,
                  ),
                ),
              ),
            _buildListSection(
              context,
              children: [
                _buildMessageItem(context, ref),
              _buildItem(context, 'TODO', Icons.task_alt, CupertinoIcons.checkmark_square, const TodoEntry()),
                _buildItem(context, 'NOTE', Icons.note, CupertinoIcons.doc_text, NotesPage()),
                _buildItem(context, '浏览历史', Icons.history, CupertinoIcons.book, const BrowsingHistoryPage()),
              ],
            ),
          ],

          /// 第二组：积分、收藏（仅登录时显示）
          if (isLoggedIn) ...[
            if (PlatformUtils.isAndroid)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  '我的',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.secondaryTextColor,
                  ),
                ),
              ),
            _buildListSection(
              context,
              children: [
                _buildItem(context, "积分", Icons.stars, CupertinoIcons.star, const CoinPage()),
                _buildItem(context, '积分排行', Icons.leaderboard, CupertinoIcons.chart_bar_alt_fill, const CoinRankPage()),
                _buildItem(context, '收藏', Icons.favorite, CupertinoIcons.heart, const CollectListPage()),
              ],
            ),
          ],

          /// 第三组：AI 配置、夜间模式、设置
          if (PlatformUtils.isAndroid)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                '通用',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.secondaryTextColor,
                ),
              ),
            ),
          _buildListSection(
            context,
            children: [
              _buildItem(context, 'AI 配置', Icons.auto_awesome, CupertinoIcons.sparkles, const AIProviderManagementPage()),
              _buildItem(context, 'AI 对话历史', Icons.history, CupertinoIcons.chat_bubble_2, const ChatHistoryPage()),
              _buildDailyReportItem(context),
              _buildThemeItem(context, ref),
              _buildItem(context, '设置', Icons.settings, CupertinoIcons.settings, const SettingsPage()),
            ],
          ),

          /// 第四组：登录/退出登录
          _buildListSection(
            context,
            children: [
              if (isLoggedIn)
                _buildLogoutItem(context, ref)
              else
                _buildLoginItem(context),
            ],
          ),
          
          // 底部占位，确保内容铺满
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 构建列表分组（根据平台自适应）
  Widget _buildListSection(BuildContext context, {required List<Widget> children}) {
    if (PlatformUtils.isIOS) {
      return CupertinoListSection.insetGrouped(
        children: children,
      );
    }
    
    // Android Material 风格
    return Column(
      children: children,
    );
  }

  /// 构建消息通知项
  Widget _buildMessageItem(BuildContext context, WidgetRef ref) {
    if (PlatformUtils.isIOS) {
      return CupertinoListTile(
        title: const Text('消息通知'),
        trailing: Consumer(
          builder: (context, ref, child) {
            final unreadCount = ref.watch(unreadMessageCountProvider);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const CupertinoListTileChevron(),
              ],
            );
          },
        ),
        onTap: () {
          navigatePlatform(context, const MessagePage());
        },
      );
    }
    
    // Android Material 风格
    return Consumer(
      builder: (context, ref, child) {
        final unreadCount = ref.watch(unreadMessageCountProvider);
        return ListTile(
          leading: Icon(Icons.notifications, color: context.primaryColor),
          title: const Text('消息通知'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.errorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: context.secondaryTextColor),
            ],
          ),
          onTap: () {
            navigatePlatform(context, const MessagePage());
          },
        );
      },
    );
  }

  /// 构建 AI 日报项（使用 BottomSheet 而非页面跳转）
  Widget _buildDailyReportItem(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoListTile(
        title: const Text('AI 日报'),
        trailing: const CupertinoListTileChevron(),
        onTap: () {
          Navigator.pop(context); // 先关闭 Drawer
          showAIDailyReportSheet(context);
        },
      );
    }
    
    // Android Material 风格
    return ListTile(
      leading: Icon(Icons.summarize, color: context.primaryColor),
      title: const Text('AI 日报'),
      trailing: Icon(Icons.chevron_right, color: context.secondaryTextColor),
      onTap: () {
        Navigator.pop(context); // 先关闭 Drawer
        showAIDailyReportSheet(context);
      },
    );
  }

  /// 构建主题切换项
  Widget _buildThemeItem(BuildContext context, WidgetRef ref) {
    if (PlatformUtils.isIOS) {
      return CupertinoListTile(
        title: const Text('夜间模式'),
        trailing: const CupertinoListTileChevron(),
        onTap: () {
          showThemePicker(context, ref);
        },
      );
    }
    
    // Android Material 风格
    return ListTile(
      leading: Icon(Icons.brightness_6, color: context.primaryColor),
      title: const Text('夜间模式'),
      trailing: Icon(Icons.chevron_right, color: context.secondaryTextColor),
      onTap: () {
        _showMaterialThemePicker(context, ref);
      },
    );
  }

  /// 构建登出项
  Widget _buildLogoutItem(BuildContext context, WidgetRef ref) {
    if (PlatformUtils.isIOS) {
      return CupertinoListTile(
        title: const Text(
          '退出登录',
          style: TextStyle(
            color: CupertinoColors.systemRed,
          ),
        ),
        onTap: () => _showLogoutDialog(context, ref),
      );
    }
    
    // Android Material 风格
    return ListTile(
      leading: Icon(Icons.logout, color: context.errorColor),
      title: Text(
        '退出登录',
        style: TextStyle(color: context.errorColor),
      ),
      onTap: () => _showLogoutDialog(context, ref),
    );
  }

  /// 构建登录项
  Widget _buildLoginItem(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoListTile(
        title: const Text(
          '登录账号',
          style: TextStyle(
            color: CupertinoColors.activeBlue,
          ),
        ),
        trailing: const CupertinoListTileChevron(),
        onTap: () => _navigateToLogin(context),
      );
    }
    
    // Android Material 风格
    return ListTile(
      leading: Icon(Icons.login, color: context.primaryColor),
      title: Text(
        '登录账号',
        style: TextStyle(color: context.primaryColor),
      ),
      trailing: Icon(Icons.chevron_right, color: context.secondaryTextColor),
      onTap: () => _navigateToLogin(context),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData materialIcon, IconData cupertinoIcon, Widget? page) {
    if (PlatformUtils.isIOS) {
      return CupertinoListTile(
        title: Text(title),
        trailing: const CupertinoListTileChevron(),
        onTap: page != null ? () {
          navigatePlatform(context, page);
        } : null,
      );
    }
    
    // Android Material 风格
    return ListTile(
      leading: Icon(materialIcon, color: context.primaryColor),
      title: Text(title),
      trailing: Icon(Icons.chevron_right, color: context.secondaryTextColor),
      onTap: page != null ? () {
        navigatePlatform(context, page);
      } : null,
    );
  }

  /// Material 风格的主题选择器
  Future<void> _showMaterialThemePicker(BuildContext context, WidgetRef ref) async {
    final themeNotifier = ref.read(themeModeProvider.notifier);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('亮色'),
              onTap: () {
                themeNotifier.setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('暗色'),
              onTap: () {
                themeNotifier.setTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('跟随系统'),
              onTap: () {
                themeNotifier.setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showThemePicker(BuildContext context, WidgetRef ref) async {
    final themeNotifier = ref.read(themeModeProvider.notifier);

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("选择主题模式"),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              themeNotifier.setTheme(ThemeMode.light);
              Navigator.pop(context);
            },
            child: const Text("亮色"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              themeNotifier.setTheme(ThemeMode.dark);
              Navigator.pop(context);
            },
            child: const Text("暗色"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              themeNotifier.setTheme(ThemeMode.system);
              Navigator.pop(context);
            },
            child: const Text("跟随系统"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text("取消"),
        ),
      ),
    );
  }
}

/// 导航到登录页面
void _navigateToLogin(BuildContext context) {
  Navigator.pop(context); // 先关闭侧边栏
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
  );
}

/// 显示退出登录确认对话框
Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
  final result = await showPlatformDialog<bool>(
    context: context,
    title: '退出登录',
    content: '确定要退出登录吗？',
    actions: [
      PlatformDialogAction(
        text: '取消',
        onPressed: () => Navigator.pop(context, false),
      ),
      PlatformDialogAction(
        text: '退出',
        isDestructive: true,
        onPressed: () => Navigator.pop(context, true),
      ),
    ],
  );

  if (result == true && context.mounted) {
    await _handleLogout(context, ref);
  }
}

/// 处理退出登录逻辑
Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
  // 显示加载指示器
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: PlatformLoadingIndicator(radius: 20),
    ),
  );

  try {
    // 调用退出登录接口
    final cgiUser = CgiUser();
    await cgiUser.logout();

    // 更新全局登录状态
    ref.read(loginStateProvider.notifier).logout();

    if (context.mounted) {
      // 关闭加载指示器
      Navigator.pop(context);
      
      // 关闭侧边栏
      Navigator.pop(context);
      
      // 显示成功提示
      await showPlatformDialog(
        context: context,
        title: '退出成功',
        content: '您已成功退出登录',
        actions: [
          PlatformDialogAction(
            text: '确定',
            onPressed: () {
              Navigator.pop(context);
              // 退出后返回登录页
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      );
    }
  } catch (e) {
    // 即使失败也要更新登录状态
    ref.read(loginStateProvider.notifier).logout();
    
    if (context.mounted) {
      // 关闭加载指示器
      Navigator.pop(context);
      
      // 显示错误提示
      await showPlatformDialog(
        context: context,
        title: '提示',
        content: '退出登录时出现问题，但本地数据已清理',
        actions: [
          PlatformDialogAction(
            text: '确定',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 关闭侧边栏
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      );
    }
  }
}
