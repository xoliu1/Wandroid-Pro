import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import 'package:wanandroid_pro/model/Todo.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';
import 'package:mmkv/mmkv.dart';

/// 番茄钟专注模式页面
class PomodoroPage extends StatefulWidget {
  final Todo? todo;
  const PomodoroPage({super.key, this.todo});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage>
    with SingleTickerProviderStateMixin {
  // 番茄钟配置
  static const _focusDuration = 25 * 60; // 25 分钟（秒）
  static const _shortBreak = 5 * 60;     // 5 分钟短休息
  static const _longBreak = 15 * 60;     // 15 分钟长休息

  late AnimationController _pulseController;
  Timer? _timer;

  int _remainingSeconds = _focusDuration;
  int _totalSeconds = _focusDuration;
  bool _isRunning = false;
  bool _isPaused = false;
  int _completedPomodoros = 0;
  _PomodoroPhase _phase = _PomodoroPhase.focus;

  // 今日统计
  int _todayFocusMinutes = 0;
  int _todayPomodoros = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadTodayStats();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadTodayStats() {
    final kv = MMKV.defaultMMKV();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = kv.decodeString('pomodoro_date') ?? '';
    if (savedDate == today) {
      _todayFocusMinutes = kv.decodeInt('pomodoro_focus_minutes', defaultValue: 0);
      _todayPomodoros = kv.decodeInt('pomodoro_count', defaultValue: 0);
    } else {
      // 新的一天，重置
      kv.encodeString('pomodoro_date', today);
      kv.encodeInt('pomodoro_focus_minutes', 0);
      kv.encodeInt('pomodoro_count', 0);
    }
    setState(() {});
  }

  void _saveTodayStats() {
    final kv = MMKV.defaultMMKV();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    kv.encodeString('pomodoro_date', today);
    kv.encodeInt('pomodoro_focus_minutes', _todayFocusMinutes);
    kv.encodeInt('pomodoro_count', _todayPomodoros);
  }

  void _startTimer() {
    _timer?.cancel(); // 防止重复创建 Timer
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _onPhaseComplete();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isPaused = true);
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _phase = _PomodoroPhase.focus;
      _remainingSeconds = _focusDuration;
      _totalSeconds = _focusDuration;
    });
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    _pulseController.stop();
    HapticFeedback.heavyImpact();

    if (_phase == _PomodoroPhase.focus) {
      // 专注完成
      _completedPomodoros++;
      _todayPomodoros++;
      _todayFocusMinutes += 25;
      _saveTodayStats();

      toastification.show(
        context: context,
        title: const Text('🍅 专注完成！休息一下吧'),
        primaryColor: MCMColors.olive,
        showProgressBar: false,
        autoCloseDuration: const Duration(seconds: 3),
      );

      // 每 4 个番茄钟后长休息
      final isLongBreak = _completedPomodoros % 4 == 0;
      setState(() {
        _phase = isLongBreak ? _PomodoroPhase.longBreak : _PomodoroPhase.shortBreak;
        _remainingSeconds = isLongBreak ? _longBreak : _shortBreak;
        _totalSeconds = _remainingSeconds;
        _isRunning = false;
        _isPaused = false;
      });
    } else {
      // 休息完成
      toastification.show(
        context: context,
        title: const Text('⏰ 休息结束，继续加油！'),
        primaryColor: MCMColors.orange,
        showProgressBar: false,
        autoCloseDuration: const Duration(seconds: 3),
      );

      setState(() {
        _phase = _PomodoroPhase.focus;
        _remainingSeconds = _focusDuration;
        _totalSeconds = _focusDuration;
        _isRunning = false;
        _isPaused = false;
      });
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bg = MCMColors.background(context);
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final phaseColor = _phase == _PomodoroPhase.focus ? MCMColors.orange : MCMColors.olive;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            MCMHeader(
              title: 'FOCUS',
              subtitle: widget.todo != null ? '专注：${widget.todo!.title}' : '番茄钟专注模式',
              leading: MCMBackButton(),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 阶段标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: phaseColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _phase == _PomodoroPhase.focus ? '🍅 专注中'
                          : _phase == _PomodoroPhase.shortBreak ? '☕ 短休息'
                          : '🌿 长休息',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: phaseColor),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 计时器圆环
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseScale = _isRunning && !_isPaused
                            ? 1.0 + _pulseController.value * 0.02
                            : 1.0;
                        return Transform.scale(
                          scale: pulseScale,
                          child: CustomPaint(
                            painter: _TimerPainter(
                              progress: _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0,
                              color: phaseColor,
                              bgColor: MCMColors.dividerColor(context),
                              isRunning: _isRunning && !_isPaused,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(_remainingSeconds),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    '第 ${_completedPomodoros + 1} 个番茄',
                                    style: TextStyle(fontSize: 13, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 控制按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRunning) ...[
                        // 重置按钮
                        GestureDetector(
                          onTap: _resetTimer,
                          child: Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: MCMColors.coral.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.stop_fill, color: MCMColors.coral, size: 24),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // 暂停/继续按钮
                        GestureDetector(
                          onTap: _isPaused ? _resumeTimer : _pauseTimer,
                          child: Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: phaseColor,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: phaseColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: Icon(
                              _isPaused ? CupertinoIcons.play_fill : CupertinoIcons.pause_fill,
                              color: Colors.white, size: 32,
                            ),
                          ),
                        ),
                      ] else ...[
                        // 开始按钮
                        GestureDetector(
                          onTap: _startTimer,
                          child: Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: phaseColor,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: phaseColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 32),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 今日统计
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: MCMColors.card(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MCMColors.dividerColor(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildStatItem('今日番茄', '$_todayPomodoros', MCMColors.orange)),
                        Container(width: 1, height: 32, color: MCMColors.dividerColor(context)),
                        Expanded(child: _buildStatItem('专注时长', '${_todayFocusMinutes}min', MCMColors.olive)),
                        Container(width: 1, height: 32, color: MCMColors.dividerColor(context)),
                        Expanded(child: _buildStatItem('已完成', '$_completedPomodoros', MCMColors.grayBlue)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: MCMColors.secondaryText(context))),
      ],
    );
  }
}

enum _PomodoroPhase { focus, shortBreak, longBreak }

/// 计时器圆环绘制
class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final bool isRunning;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 8.0;

    // 背景圆环
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // 进度圆弧
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // 进度端点圆点
    if (progress > 0 && progress < 1) {
      final endAngle = -math.pi / 2 + sweepAngle;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);
      canvas.drawCircle(
        Offset(endX, endY),
        strokeWidth / 2 + 2,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(endX, endY),
        strokeWidth / 2 - 1,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.color != color || old.isRunning != isRunning;
}
