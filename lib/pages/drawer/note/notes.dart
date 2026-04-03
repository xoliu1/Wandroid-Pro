import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/drawer/note/note_widget.dart';
import 'package:notes_app/providers/note_provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';

import 'note_editor_v2.dart';

class NotesPage extends ConsumerWidget {
  NotesPage({super.key});

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  void refreshNotes(WidgetRef ref) async {
    _refreshController.requestRefresh();
    await ref.read(noteProvider.notifier).initializeNotes();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(noteProvider);
    final noteWidgets = notes.map((note) => NoteWidget(note: note)).toList();

    return Scaffold(
        backgroundColor: AppColors.backgroundColor(context),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // 添加新笔记
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const NoteEditorV2(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: SmartRefresher(
          header: const WaterDropHeader(),
          controller: _refreshController,
          onRefresh: () => refreshNotes(ref),
          child: SingleChildScrollView(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 60.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => refreshNotes(ref),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              notes.isEmpty
                  ? SizedBox(
                      height: 380,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: 250,
                              child: Image.asset('assets/images/empty3.png')),
                          Text(
                            "You don't have any notes yet",
                            style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText(context)),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: noteWidgets.asMap().entries.map((entry) {
                        return AnimatedListItem(
                          index: entry.key,
                          child: entry.value,
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 80),
            ],
          ),
          ),
        ));
  }
}
