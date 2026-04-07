import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/model/note.dart';
import 'package:wanandroid_pro/pages/drawer/note/note_widget.dart';
import 'package:wanandroid_pro/providers/note_provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/app_colors.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';

import 'note_editor_v2.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void refreshNotes() async {
    _refreshController.requestRefresh();
    await ref.read(noteProvider.notifier).initializeNotes();
    _refreshController.refreshCompleted();
  }

  List<Note> _filterNotes(List<Note> notes) {
    if (_searchQuery.isEmpty) return notes;
    final query = _searchQuery.toLowerCase();
    return notes.where((note) => note.content.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context, ) {
    final notes = ref.watch(noteProvider);
    final filteredNotes = _filterNotes(notes);
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);
    final bg = AppColors.backgroundColor(context);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
        onRefresh: refreshNotes,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: refreshNotes,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 搜索框
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: divColor, width: 1),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: '搜索笔记内容...',
                          hintStyle: TextStyle(color: subColor.withOpacity(0.5), fontSize: 15),
                          prefixIcon: Icon(CupertinoIcons.search, color: MCMColors.orange.withOpacity(0.6), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: subColor, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                  ),
                  // 搜索结果数量提示
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
                      child: Text(
                        '找到 ${filteredNotes.length} 条笔记',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            // 笔记列表
            if (filteredNotes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_searchQuery.isNotEmpty) ...[
                        MCMStarburst(size: 56, color: MCMColors.mustard.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          '没有找到相关笔记',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: subColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '试试其他关键词',
                          style: TextStyle(fontSize: 13, color: subColor.withOpacity(0.6)),
                        ),
                      ] else ...[
                        SizedBox(height: 250, child: Image.asset('assets/images/empty3.png')),
                        Text(
                          "You don't have any notes yet",
                          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = filteredNotes[index];
                    return AnimatedListItem(
                      index: index,
                      child: NoteWidget(note: note),
                    );
                  },
                  childCount: filteredNotes.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
