import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

// ============================================================
// 音频波形可视化组件
// ============================================================

class AudioVisualizer extends StatefulWidget {
  final bool isActive;
  final Color color;
  final int barCount;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.isActive,
    this.color = AppTheme.primary,
    this.barCount = 20,
    this.height = 40,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + _random.nextInt(400)),
      );
      return controller;
    });

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isActive) _startAnimation();
  }

  void _startAnimation() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 30), () {
        if (mounted && widget.isActive) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimation() {
    for (final c in _controllers) {
      c.animateTo(0.1, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3,
                height: widget.height * _animations[i].value,
                decoration: BoxDecoration(
                  color: widget.color
                      .withValues(alpha: 0.4 + _animations[i].value * 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
