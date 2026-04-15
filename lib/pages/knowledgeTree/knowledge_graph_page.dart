import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/pages/knowledgeTree/tree_article_page.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';

import '../../providers/chapter_provider.dart';
import '../../remote/Api.dart';

/// 知识图谱节点
class _GraphNode {
  final Chapter chapter;
  final bool isParent;
  Offset position;
  Offset velocity;
  final double radius;
  final Color color;

  _GraphNode({
    required this.chapter,
    required this.isParent,
    required this.position,
    required this.radius,
    required this.color,
  }) : velocity = Offset.zero;
}

/// 知识图谱边
class _GraphEdge {
  final _GraphNode from;
  final _GraphNode to;
  _GraphEdge({required this.from, required this.to});
}

/// 知识图谱可视化页面（力导向图）
class KnowledgeGraphPage extends ConsumerStatefulWidget {
  const KnowledgeGraphPage({super.key});
  @override
  ConsumerState<KnowledgeGraphPage> createState() => _KnowledgeGraphPageState();
}

class _KnowledgeGraphPageState extends ConsumerState<KnowledgeGraphPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_GraphNode> _nodes = [];
  final List<_GraphEdge> _edges = [];
  _GraphNode? _draggedNode;
  _GraphNode? _selectedNode;
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;
  double _previousScale = 1.0; // 记录上一次缩放值
  bool _isInitialized = false;
  Size _canvasSize = Size.zero; // 记录画布大小

  static const _parentColors = [
    MCMColors.orange, MCMColors.grayBlue, MCMColors.olive,
    MCMColors.mustard, MCMColors.coral, MCMColors.walnut,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_simulateForces);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _initGraph(List<Chapter> chapters) {
    if (_isInitialized) return;
    _isInitialized = true;

    final rng = math.Random(42);
    // 使用画布中心作为图谱中心
    final centerX = _canvasSize.width > 0 ? _canvasSize.width / 2 : 200.0;
    final centerY = _canvasSize.height > 0 ? _canvasSize.height / 2 : 300.0;

    // 只取前 12 个大分类，避免太拥挤
    final topChapters = chapters.take(12).toList();

    for (int i = 0; i < topChapters.length; i++) {
      final chapter = topChapters[i];
      final angle = (2 * math.pi * i) / topChapters.length;
      final dist = 180.0 + rng.nextDouble() * 40;
      final color = _parentColors[i % _parentColors.length];

      final parentNode = _GraphNode(
        chapter: chapter,
        isParent: true,
        position: Offset(centerX + dist * math.cos(angle), centerY + dist * math.sin(angle)),
        radius: 28,
        color: color,
      );
      _nodes.add(parentNode);

      // 子节点（最多取 6 个）
      final children = chapter.children.take(6).toList();
      for (int j = 0; j < children.length; j++) {
        final childAngle = angle + (j - children.length / 2) * 0.3;
        final childDist = dist + 80 + rng.nextDouble() * 30;
        final childNode = _GraphNode(
          chapter: children[j],
          isParent: false,
          position: Offset(centerX + childDist * math.cos(childAngle), centerY + childDist * math.sin(childAngle)),
          radius: 16,
          color: color.withOpacity(0.7),
        );
        _nodes.add(childNode);
        _edges.add(_GraphEdge(from: parentNode, to: childNode));
      }
    }

    _animController.repeat();
    // 模拟一段时间后停止
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _animController.stop();
    });
  }

  void _simulateForces() {
    const damping = 0.85;
    const repulsion = 5000.0;
    const springLength = 100.0;
    const springK = 0.01;
    const centerGravity = 0.002;
    // 使用画布中心作为引力中心
    final centerX = _canvasSize.width > 0 ? _canvasSize.width / 2 : 200.0;
    final centerY = _canvasSize.height > 0 ? _canvasSize.height / 2 : 300.0;

    // 斥力（所有节点之间）
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final dx = _nodes[i].position.dx - _nodes[j].position.dx;
        final dy = _nodes[i].position.dy - _nodes[j].position.dy;
        final dist = math.sqrt(dx * dx + dy * dy).clamp(10.0, 1000.0);
        final force = repulsion / (dist * dist);
        final fx = force * dx / dist;
        final fy = force * dy / dist;
        _nodes[i].velocity = _nodes[i].velocity + Offset(fx, fy);
        _nodes[j].velocity = _nodes[j].velocity - Offset(fx, fy);
      }
    }

    // 弹簧力（连接的边）
    for (final edge in _edges) {
      final dx = edge.to.position.dx - edge.from.position.dx;
      final dy = edge.to.position.dy - edge.from.position.dy;
      final dist = math.sqrt(dx * dx + dy * dy).clamp(1.0, 1000.0);
      final force = springK * (dist - springLength);
      final fx = force * dx / dist;
      final fy = force * dy / dist;
      edge.from.velocity = edge.from.velocity + Offset(fx, fy);
      edge.to.velocity = edge.to.velocity - Offset(fx, fy);
    }

    // 中心引力
    for (final node in _nodes) {
      final dx = centerX - node.position.dx;
      final dy = centerY - node.position.dy;
      node.velocity = node.velocity + Offset(dx * centerGravity, dy * centerGravity);
    }

    // 更新位置
    for (final node in _nodes) {
      if (node == _draggedNode) continue;
      node.velocity = node.velocity * damping;
      node.position = node.position + node.velocity;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(chapterProvider);

    return chaptersAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (chapters) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (_canvasSize == Size.zero) {
              _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            }
            _initGraph(chapters);
            return _buildGraphView();
          },
        );
      },
    );
  }

  Widget _buildGraphView() {
    return GestureDetector(
      onScaleStart: (details) {
        _previousScale = _scale;
        // 检查是否点击了某个节点
        final localPos = (details.localFocalPoint - _panOffset) / _scale;
        for (final node in _nodes.reversed) {
          final dist = (node.position - localPos).distance;
          if (dist <= node.radius + 8) {
            _draggedNode = node;
            return;
          }
        }
      },
      onScaleUpdate: (details) {
        if (_draggedNode != null) {
          setState(() {
            _draggedNode!.position = (details.localFocalPoint - _panOffset) / _scale;
            _draggedNode!.velocity = Offset.zero;
          });
        } else {
          setState(() {
            if (details.scale != 1.0) {
              // details.scale 是累积值，需要基于起始 scale 计算
              _scale = (_previousScale * details.scale).clamp(0.3, 3.0);
            }
            _panOffset += details.focalPointDelta;
          });
        }
      },
      onScaleEnd: (_) {
        _draggedNode = null;
      },
      onTapUp: (details) {
        final localPos = (details.localPosition - _panOffset) / _scale;
        for (final node in _nodes.reversed) {
          final dist = (node.position - localPos).distance;
          if (dist <= node.radius + 8) {
            setState(() => _selectedNode = node);
            if (node.chapter.children.isNotEmpty) {
              showCupertinoModalPopup(
                context: context,
                builder: (context) => SizedBox.expand(
                  child: TreeArticlePage(chapter: node.chapter),
                ),
              );
            }
            return;
          }
        }
        setState(() => _selectedNode = null);
      },
      child: ClipRect(
        child: CustomPaint(
          painter: _GraphPainter(
            nodes: _nodes,
            edges: _edges,
            selectedNode: _selectedNode,
            panOffset: _panOffset,
            scale: _scale,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// 图谱绘制器
class _GraphPainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;
  final _GraphNode? selectedNode;
  final Offset panOffset;
  final double scale;
  final bool isDark;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    this.selectedNode,
    required this.panOffset,
    required this.scale,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);

    // 绘制边
    final edgePaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      edgePaint.color = edge.from.color.withOpacity(0.2);
      canvas.drawLine(edge.from.position, edge.to.position, edgePaint);
    }

    // 绘制节点
    for (final node in nodes) {
      final isSelected = node == selectedNode;

      // 光晕
      if (isSelected) {
        canvas.drawCircle(
          node.position,
          node.radius + 6,
          Paint()..color = node.color.withOpacity(0.2),
        );
      }

      // 节点圆
      canvas.drawCircle(
        node.position,
        node.radius,
        Paint()..color = node.color.withOpacity(node.isParent ? 0.15 : 0.1),
      );
      canvas.drawCircle(
        node.position,
        node.radius,
        Paint()
          ..color = node.color.withOpacity(isSelected ? 1.0 : 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.5 : 1.5,
      );

      // 文字标签
      final label = node.chapter.name.length > 6
          ? '${node.chapter.name.substring(0, 6)}...'
          : node.chapter.name;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: node.isParent ? 11 : 9,
            fontWeight: node.isParent ? FontWeight.w700 : FontWeight.w500,
            color: isDark ? Colors.white.withOpacity(0.9) : node.color,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: node.radius * 3);

      tp.paint(
        canvas,
        Offset(
          node.position.dx - tp.width / 2,
          node.position.dy - tp.height / 2,
        ),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GraphPainter old) => true;
}
