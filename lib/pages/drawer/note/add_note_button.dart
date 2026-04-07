import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/model/note.dart';
import 'package:wanandroid_pro/providers/note_provider.dart';
import 'package:wanandroid_pro/utils/functions.dart';

import 'note_editor.dart';


class AddNoteButton extends ConsumerWidget {
  const AddNoteButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        CupertinoIcons.add,
        color: Colors.black.withOpacity(0.7),
        size: 25,
      ),
        onPressed: () async {
          final note = Note(
            id: randId(16),
            content: '',
            date: DateTime.now(),
            lastModified: DateTime.now(),
          );
          final result = await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const NoteEditor(existingNote: null),
            ),
          );
          if (result != null && result is Note) {
            ref.read(noteProvider.notifier).addNote(result);
          }
        },
    );
  }
}
