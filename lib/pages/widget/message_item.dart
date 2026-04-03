import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../model/message.dart';
import '../../utils/animations.dart';
import '../../utils/app_colors.dart';
import '../../utils/functions.dart';

class MessageItem extends StatelessWidget {
  final Message message;

  const MessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => _handleTap(context),
      child: CupertinoListTile(
        padding: const EdgeInsets.all(12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getTagColor(),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          _getTagIcon(),
          color: CupertinoColors.white,
          size: 20,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  message.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (message.isRead == 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                message.fromUser,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.link(context),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.niceDate,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.tertiaryText(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getTagColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  message.tag,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getTagColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Color _getTagColor() {
    switch (message.tag) {
      case '系统消息':
        return CupertinoColors.systemPurple;
      case '新回答':
        return CupertinoColors.systemGreen;
      case '评论回复':
        return CupertinoColors.systemOrange;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getTagIcon() {
    switch (message.tag) {
      case '系统消息':
        return CupertinoIcons.bell_fill;
      case '新回答':
        return CupertinoIcons.chat_bubble_2_fill;
      case '评论回复':
        return CupertinoIcons.reply_all;
      default:
        return CupertinoIcons.envelope_fill;
    }
  }

  void _handleTap(BuildContext context) {
    if (message.fullLink.isNotEmpty) {
      final uri = Uri.parse(message.fullLink);
      launchInApp(context, uri);
    }
  }
}