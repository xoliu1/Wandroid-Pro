import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/model/note.dart';
import 'package:wanandroid_pro/providers/note_provider.dart';
import 'package:wanandroid_pro/utils/functions.dart' show randId;


class NoteEditor extends ConsumerWidget {
  final Note? existingNote;

  const NoteEditor({super.key, this.existingNote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentController = TextEditingController(text: existingNote?.content ?? '');

    void saveNote() {
      final content = contentController.text;
      if (content.isEmpty) return;

      final note = Note(
        id: existingNote?.id ?? randId(16), // 确保 id 不为空
        content: content,
        date: existingNote?.date ?? DateTime.now(),
        lastModified: DateTime.now(),
      );

      if (existingNote == null) {
        ref.read(noteProvider.notifier).addNote(note);
      } else {
        ref.read(noteProvider.notifier).updateNote(existingNote!.id, note);
      }
      Navigator.pop(context);
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(existingNote == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          autofocus: true,
          controller: contentController,
          decoration: const InputDecoration(
            hintText: 'Write your note here...',
            border: InputBorder.none,
          ),
          maxLines: null,
          expands: true,
        ),
      ),
    );
  }
}