import 'package:flutter/material.dart';

/// A simple shimmering skeleton block. No external package needed.
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            color: Color.lerp(
              Colors.grey.shade300,
              Colors.grey.shade100,
              _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  const SkeletonListLoader({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 16, width: 180),
              const SizedBox(height: 8),
              SkeletonBox(height: 12, width: 120),
            ],
          ),
        ),
      ),
    );
  }
}