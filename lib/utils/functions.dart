import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:wanandroid_pro/model/note.dart';
import 'package:table_calendar/table_calendar.dart';
import '../ai/ui/article_webview_page.dart';

String randId(int length) {
  return '${Random().nextInt(100000)}';
}

bool deadlineApproaching(DateTime deadline) {
  final now = DateTime.now();
  final diff = deadline.difference(now);
  return isSameDay(DateTime.now(), deadline) && diff.inHours < 2;
}

List<Note> sortNotesByRelevance(List<Note> notes) {
  notes.sort((a, b) {
    return -1 * (a.lastModified.compareTo(b.lastModified));
  });
  return notes;
}

bool timeElapsed(DateTime date) {
  return date.isBefore(DateTime.now());
}

bool nameValid(String name) {
  return name.trim().isNotEmpty;
}

/// HTML2中文
extension StringHtmlExtension on String {
  String decodeHtmlEntities() {
    return replaceAll(RegExp("(<em[^>]*>)|(</em>)"), "")
        .replaceAll(RegExp("\n{2,}"), "\n")
        .replaceAll(RegExp("s{2,}"), " ")
        .replaceAll("&ndash;", "–")
        .replaceAll("&mdash;", "—")
        .replaceAll("&lsquo;", "‘")
        .replaceAll("&rsquo;", "’")
        .replaceAll("&sbquo;", "‚")
        .replaceAll("&ldquo;", "“")
        .replaceAll("&rdquo;", "”")
        .replaceAll("&bdquo;", "„")
        .replaceAll("&amp;", "&")
        .replaceAll("&permil;", "‰")
        .replaceAll("&lsaquo;", "‹")
        .replaceAll("&rsaquo;", "›")
        .replaceAll("&euro;", "€")
        .replaceAll("&cent;", "¢")
        .replaceAll("&pound;", "£")
        .replaceAll("&yen;", "¥")
        .replaceAll("&sect;", "§")
        .replaceAll("&copy;", "©")
        .replaceAll("&reg;", "®")
        .replaceAll("&quot;", "'")
        .replaceAll("&zwj", ")")
        .replaceAll("&apos;", "'")
        .replaceAll("&nbsp;", " ")
        .replaceAll("&iexcl;", "¡")
        .replaceAll("&iquest;", "¿")
        .replaceAll("&laquo;", "«")
        .replaceAll("<p>", "")
        .replaceAll("&middot;", "·")
        .replaceAll("&hellip;", "...")
        .replaceAll("</p>", "")
        .replaceAll("</br>", "\n")
        .replaceAll("<br>", "\n");
  }
}

/// 在 App 内打开 URL（统一使用 ArticleWebViewPage）
void launchInApp(BuildContext context, Uri url) {
  Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (context) => ArticleWebViewPage(
        url: url.toString(),
        title: null, // 标题会从网页中提取
      ),
    ),
  );
}
