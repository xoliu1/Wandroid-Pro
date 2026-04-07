import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/model/note.dart';

import '../ai/providers/user_context_provider.dart';
import '../model/db/sqflite.dart';
import '../utils/functions.dart';

class NoteNotifier extends Notifier<List<Note>> {
  @override
  List<Note> build() {
    initializeNotes();
    return [];
  }

  /// 通知用户画像需要刷新（防抖 5 秒）
  void _notifyContextRefresh() {
    try {
      ref.read(userContextProvider.notifier).scheduleRefresh();
    } catch (_) {
      // Provider 可能尚未初始化，忽略
    }
  }

  void addNote(Note note) {
    if (note.id.isEmpty) {
      note = note.copyWith(id: randId(16)); // 确保 id 不为空
    }
    try {
      Db.insertNote(note.toMap());
      state = sortNotesByRelevance([...state, note]);
      log('Note added: ${note.content}');
      _notifyContextRefresh();
    } catch (e) {
      log('Failed to add note: $e');
    }
  }

  void updateNote(String id, Note updatedNote) {
    try {
      if (state.any((note) => note.id == id)) {
        debugPrint('Updating existing note with ID: $id');
        Db.updateNote(updatedNote.toMap());
        state = sortNotesByRelevance(state.map((note) => note.id == id ? updatedNote : note).toList());
        debugPrint('Note updated: ${updatedNote.content}');
        _notifyContextRefresh();
      } else {
        debugPrint('Note with ID $id not found, adding as new note');
        addNote(updatedNote);
      }
    } catch (e) {
      debugPrint('Failed to update note: $e');
    }
  }

  void deleteNote(String id) {
    try {
      Db.deleteNote(id);
      state = sortNotesByRelevance(state.where((note) => note.id != id).toList());
      debugPrint('Note deleted: $id');
      _notifyContextRefresh();
    } catch (e) {
      debugPrint('Failed to delete note: $e');
    }
  }

  Future<void> initializeNotes() async {
    try {
      final notes = await Db.getNotes();
      debugPrint('Loaded notes: ${notes.length}');
      state = sortNotesByRelevance(notes.map((map) => Note.fromMap(map)).toList());
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize notes: $e');
      debugPrint('Stack trace: $stackTrace');
      state = [];
    }
  }
}

final noteProvider = NotifierProvider<NoteNotifier, List<Note>>(() => NoteNotifier());