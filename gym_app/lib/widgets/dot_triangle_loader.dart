import 'package:flutter/material.dart';
import 'package:gym_app/utils/constants.dart';

class DotTriangleLoader extends StatefulWidget {
  final double dotSize;
  final Color? color;

  const DotTriangleLoader({super.key, this.dotSize = 16, this.color});

  @override
  State<DotTriangleLoader> createState() => _DotTriangleLoaderState();
}

class _DotTriangleLoaderState extends State<DotTriangleLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _lerp(Offset start, Offset end, double t) {
    return Offset.lerp(start, end, t) ?? end;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.dotSize;
    final spacing = size * 0.8;
    
    // Centrar el cargador dentro de su propio espacio
    return Center(
      child: SizedBox(
        width: size * 2.5,
        height: size * 2.5,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_controller.value);
            
            final top = Offset(size * 0.75, 0);
            final left = Offset(0, size * 1.2);
            final right = Offset(size * 1.5, size * 1.2);

            final positions = [
              _lerp(top, right, t),
              _lerp(left, top, t),
              _lerp(right, left, t),
            ];

            return Stack(
              clipBehavior: Clip.none,
              children: [
                _Dot(
                  position: positions[0],
                  size: size,
                  color: widget.color ?? const Color(0xFF1E88E5),
                ),
                _Dot(
                  position: positions[1],
                  size: size,
                  color: widget.color != null ? widget.color! : DARK_BG,
                ),
                _Dot(
                  position: positions[2],
                  size: size,
                  color: widget.color != null ? widget.color! : WHITE,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Offset position;
  final double size;
  final Color color;

  const _Dot({required this.position, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
