import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'custom_loading_indicator.dart';

/// Özel animasyonlu refresh indicator
/// RefreshIndicator yerine kullanılır
/// CustomLoadingIndicator kullanarak özel görsel sağlar
class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final double? displacement;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.displacement,
  });

  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator> {
  bool _isRefreshing = false;
  double _dragOffset = 0.0;
  final double _refreshTriggerDistance = 80.0;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _dragOffset = 0.0;
        });
      }
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels < 0 && !_isRefreshing) {
        setState(() {
          _dragOffset = -metrics.pixels;
        });
      } else if (metrics.pixels >= 0 && _dragOffset > 0) {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragOffset >= _refreshTriggerDistance && !_isRefreshing) {
        _handleRefresh();
      } else if (_dragOffset > 0) {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        children: [
          Transform.translate(
            offset: Offset(0, _isRefreshing ? 0 : math.max(0, _dragOffset - _refreshTriggerDistance)),
            child: widget.child,
          ),
          if (_dragOffset > 0 || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _CustomRefreshHeader(
                  dragOffset: _dragOffset,
                  refreshTriggerDistance: _refreshTriggerDistance,
                  isRefreshing: _isRefreshing,
                  color: widget.color ?? Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomRefreshHeader extends StatelessWidget {
  final double dragOffset;
  final double refreshTriggerDistance;
  final bool isRefreshing;
  final Color color;

  const _CustomRefreshHeader({
    required this.dragOffset,
    required this.refreshTriggerDistance,
    required this.isRefreshing,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = math.min(dragOffset / refreshTriggerDistance, 1.0);
    final headerHeight = math.max(60.0, dragOffset);

    return Container(
      height: headerHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: isRefreshing
          ? CustomLoadingIndicator(
              size: 30.0,
              color: color,
              strokeWidth: 2.5,
            )
          : Transform.scale(
              scale: progress,
              child: Opacity(
                opacity: progress,
                child: CustomLoadingIndicator(
                  size: 30.0,
                  color: color,
                  strokeWidth: 2.5,
                ),
              ),
            ),
    );
  }
}

