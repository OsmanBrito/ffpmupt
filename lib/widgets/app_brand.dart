import 'package:ffpmupt/app_branding.dart';
import 'package:ffpmupt/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: appName,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.forest],
          ),
          borderRadius: BorderRadius.circular(size * 0.27),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.14),
              blurRadius: size * 0.25,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: CustomPaint(painter: _CommunityMarkPainter()),
      ),
    );
  }
}

class _CommunityMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cream = Paint()..color = const Color(0xfffff7e8);
    final softGold = Paint()..color = const Color(0xfff7dfae);
    final gold = Paint()..color = AppColors.gold;
    final mintStroke = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.075;
    final creamStroke = Paint()
      ..color = cream.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.064;
    final goldStroke = Paint()
      ..color = gold.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.043;

    canvas
      ..drawCircle(
        Offset(size.width * 0.76, size.height * 0.22),
        size.width * 0.055,
        gold,
      )
      ..drawCircle(
        Offset(size.width * 0.5, size.height * 0.33),
        size.width * 0.074,
        softGold,
      )
      ..drawCircle(
        Offset(size.width * 0.31, size.height * 0.46),
        size.width * 0.062,
        cream,
      )
      ..drawCircle(
        Offset(size.width * 0.69, size.height * 0.46),
        size.width * 0.062,
        cream,
      );

    final left = Path()
      ..moveTo(size.width * 0.24, size.height * 0.72)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.59,
        size.width * 0.34,
        size.height * 0.54,
        size.width * 0.44,
        size.height * 0.64,
      );
    final right = Path()
      ..moveTo(size.width * 0.76, size.height * 0.72)
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.59,
        size.width * 0.66,
        size.height * 0.54,
        size.width * 0.56,
        size.height * 0.64,
      );
    final center = Path()
      ..moveTo(size.width * 0.37, size.height * 0.73)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.55,
        size.width * 0.62,
        size.height * 0.55,
        size.width * 0.63,
        size.height * 0.73,
      );
    final connection = Path()
      ..moveTo(size.width * 0.31, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.86,
        size.width * 0.69,
        size.height * 0.76,
      );
    canvas
      ..drawPath(left, creamStroke)
      ..drawPath(right, creamStroke)
      ..drawPath(center, mintStroke)
      ..drawPath(connection, goldStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppBrandLockup extends StatelessWidget {
  const AppBrandLockup({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBrandMark(size: compact ? 34 : 44),
        const SizedBox(width: 10),
        Text(
          appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (compact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                  ),
        ),
      ],
    );
  }
}
