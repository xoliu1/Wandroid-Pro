import 'package:flutter_test/flutter_test.dart';
import 'package:wanandroid_pro/ai/providers/smart_presets_provider.dart';

void main() {
  group('SmartPresetsService', () {
    late SmartPresetsService service;

    setUp(() {
      service = SmartPresetsService();
    });

    test('应该返回默认预设问题', () {
      final defaultPresets = service.getDefaultPresetsForTest();
      
      expect(defaultPresets.length, greaterThanOrEqualTo(10));
      expect(defaultPresets.any((p) => p.title == '学习方法优化'), true);
      expect(defaultPresets.any((p) => p.title == '代码优化建议'), true);
      expect(defaultPresets.any((p) => p.title == '项目创意启发'), true);
    });

    test('应该根据上下文生成预设问题', () {
      final context = {
        'recentBrowsing': {
          'hasData': true,
          'todayCount': 5,
          'recentTitles': ['Flutter 状态管理指南'],
        },
        'todos': {
          'hasData': true,
          'pendingCount': 3,
          'todayCompletedCount': 2,
        },
        'recentNotes': {
          'hasData': true,
          'todayCount': 2,
        },
        'categories': {
          'hasData': true,
          'topCategories': [
            {'category': 'Android', 'count': 10}
          ],
        },
      };

      final presets = service.generatePresetsFromContextForTest(context);

      expect(presets.length, greaterThan(0));
      expect(presets.any((p) => p.title == '总结今天的学习'), true);
      expect(presets.any((p) => p.title == '任务优先级建议'), true);
      expect(presets.any((p) => p.title == '学习效率分析'), true);
      expect(presets.any((p) => p.title == '知识盲点分析'), true);
    });

    test('空上下文应该返回空预设列表', () {
      final context = {
        'recentBrowsing': {'hasData': false},
        'todos': {'hasData': false},
        'recentNotes': {'hasData': false},
        'categories': {'hasData': false},
      };

      final presets = service.generatePresetsFromContextForTest(context);

      expect(presets, isEmpty);
    });

    test('生成的预设应该包含个性化信息', () {
      final context = {
        'recentBrowsing': {
          'hasData': true,
          'todayCount': 5,
          'recentTitles': ['深入理解 Flutter Widget'],
        },
        'todos': {
          'hasData': false,
        },
        'recentNotes': {
          'hasData': false,
        },
        'categories': {
          'hasData': false,
        },
      };

      final presets = service.generatePresetsFromContextForTest(context);
      
      final hasContextAttached = presets.any((p) =>
        (p.context ?? '').contains('深入理解 Flutter Widget')
      );
      expect(hasContextAttached, true);
    });

    test('预设数量不应超过最大限制', () async {
      // 注意：这个测试需要 mock 数据库，这里仅做逻辑验证
      // 实际测试时需要配置测试环境

      final context = {
        'recentBrowsing': {
          'hasData': true,
          'todayCount': 10,
          'recentTitles': List.generate(10, (i) => '文章 $i'),
        },
        'todos': {
          'hasData': true,
          'pendingCount': 20,
          'todayCompletedCount': 10,
        },
        'recentNotes': {
          'hasData': true,
          'todayCount': 15,
        },
        'categories': {
          'hasData': true,
          'topCategories': [
            {'category': 'Android', 'count': 50},
            {'category': 'iOS', 'count': 30},
            {'category': 'Flutter', 'count': 20},
          ],
        },
      };

      final presets = service.generatePresetsFromContextForTest(context);

      expect(presets.length, greaterThan(0));
      expect(presets.length, lessThanOrEqualTo(6));
    });
  });
}
