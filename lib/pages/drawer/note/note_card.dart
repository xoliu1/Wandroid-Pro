import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/model/note.dart';
import 'package:notes_app/utils/app_colors.dart';

class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: AppColors.cardBackground(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        onLongPress: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.content,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Divider(color: AppColors.divider(context), height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppColors.iconSecondary(context)),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(note.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.tertiaryText(context),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: AppColors.iconSecondary(context)),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(note.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.tertiaryText(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}