import 'dart:convert';

import '../core/logger.dart';

class OpenAISSEParseResult {
  final List<String> deltas;
  final String remainingBuffer;
  final bool sawDone;

  const OpenAISSEParseResult({
    required this.deltas,
    required this.remainingBuffer,
    this.sawDone = false,
  });
}

class OpenAISSEParser {
  OpenAISSEParser._();

  static OpenAISSEParseResult parse(String buffer) {
    final deltas = <String>[];
    var sawDone = false;

    final lines = buffer.split('\n');
    final remainingBuffer = lines.isEmpty ? '' : lines.last;

    for (var i = 0; i < lines.length - 1; i++) {
      final line = lines[i];
      if (line.isEmpty || !line.startsWith('data: ')) {
        continue;
      }

      final data = line.substring(6).trim();
      if (data == '[DONE]') {
        sawDone = true;
        continue;
      }

      try {
        final json = jsonDecode(data);
        final delta = json['choices']?[0]?['delta'];
        final content = delta?['content'];
        if (content != null && content is String && content.isNotEmpty) {
          deltas.add(content);
        }
      } catch (e) {
        AILogger.warning('解析 SSE 数据失败: $e', tag: 'OpenAISSEParser');
      }
    }

    return OpenAISSEParseResult(
      deltas: deltas,
      remainingBuffer: remainingBuffer,
      sawDone: sawDone,
    );
  }
}
