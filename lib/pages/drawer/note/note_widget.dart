import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/model/note.dart';
import 'package:notes_app/providers/note_provider.dart';
import 'package:notes_app/utils/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:toastification/toastification.dart';

import 'note_editor_v2.dart';

class NoteWidget extends ConsumerWidget {
  final Note note;

  const NoteWidget({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteColor = isDark
        ? const Color.fromARGB(255, 60, 55, 35)
        : const Color.fromARGB(255, 255, 246, 200);
    final noteNotifier = ref.read(noteProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: InkWell(
        focusColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
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
          onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => NoteEditorV2(existingNote: note,),
            ),
          );
        },
        child: Container(
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          decoration: BoxDecoration(
              color: noteColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: noteColor.withOpacity(0.2),
                  blurRadius: 5,
                  spreadRadius: 5,
                  offset: const Offset(0, 0),
                )
              ]),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 125,
                    width: double.infinity,
                    child: ListView(
                      padding: const EdgeInsets.only(top: 10, bottom: 5),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 8.0),
                        Text(
                          note.content,
                          style: TextStyle(
                              fontSize: 16,
                              overflow: TextOverflow.clip,
                              color: AppColors.primaryText(context)),
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                          color: noteColor,
                          blurRadius: 5,
                          spreadRadius: 10,
                          offset: const Offset(0, -5))
                    ]),
                    child: Text(
                      (!isSameDay(DateTime.now(), note.lastModified)
                          ? DateFormat.yMMMMd().format(note.lastModified)
                          : DateFormat.jm().format(note.lastModified)),
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText(context)),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: -0,
                bottom: 15,
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          CupertinoIcons.pencil,
                          color: isDark ? Colors.black : Colors.white,
                          size: 16,
                        )),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
