import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wanandroid_pro/model/note.dart';
import 'package:wanandroid_pro/providers/note_provider.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:toastification/toastification.dart';

import 'note_editor_v2.dart';

class NoteWidget extends ConsumerWidget {
  final Note note;

  const NoteWidget({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);
    final noteNotifier = ref.read(noteProvider.notifier);

    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => NoteEditorV2(existingNote: note),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            height: 80,
            margin: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    noteNotifier.deleteNote(note.id);
                    toastification.show(
                      context: context,
                      title: const Text('笔记已删除'),
                      primaryColor: Colors.red,
                      showProgressBar: false,
                      animationDuration: const Duration(milliseconds: 200),
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 50),
                    height: 70,
                    width: double.infinity,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '删除笔记',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.w600),
                        ),
                        Icon(
                          CupertinoIcons.delete,
                          size: 20,
                          color: Colors.red,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: divColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: MCMColors.darkBrown.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧橙色竖条
              Container(
                width: 3,
                decoration: const BoxDecoration(
                  color: MCMColors.orange,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
              // 内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 笔记内容
                      Text(
                        note.content,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.45,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // 底部信息行
                      Row(
                        children: [
                          // 日期标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: MCMColors.orange.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.calendar,
                                  size: 11,
                                  color: MCMColors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (!isSameDay(DateTime.now(), note.lastModified)
                                      ? DateFormat('MM/dd').format(note.lastModified)
                                      : '今天'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: MCMColors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 时间标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: MCMColors.grayBlue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.clock,
                                  size: 11,
                                  color: MCMColors.grayBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('HH:mm').format(note.lastModified),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: MCMColors.grayBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // 笔记图标
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 14,
                            color: subColor.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}