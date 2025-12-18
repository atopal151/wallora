import 'package:flutter/material.dart';

class AnimatedNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AnimatedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar>
    with TickerProviderStateMixin {
  late AnimationController _positionController;
  late Animation<double> _positionAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _positionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _positionAnimation = CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeInOutCubic,
    );
    _positionController.value = 1.0; // Başlangıçta animasyon tamamlanmış durumda
  }

  @override
  void didUpdateWidget(AnimatedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _positionController.reset();
      _positionController.forward();
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 60,
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 18, top: 7),
      decoration: BoxDecoration(
        color: Color(0xFFfafafa), // Her zaman beyaz
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // Siyah bar arka plan - dalga efekti ile çizilmiş
          AnimatedBuilder(
            animation: _positionAnimation,
            builder: (context, child) {
              return Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: WavePainter(
                    selectedIndex: widget.currentIndex,
                    previousIndex: _previousIndex,
                    animationValue: _positionAnimation.value,
                    isDark: isDark,
                  ),
                ),
              );
            },
          ),
          // İkonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_max),
              _buildNavItem(1, Icons.favorite),
              _buildNavItem(2, Icons.settings),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = widget.currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Tüm alan tıklanabilir
        onTap: () => widget.onTap(index),
        child: SizedBox.expand(
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              width: isSelected ? 50 : 50,
              height: isSelected ? 50 : 50,
              child: isSelected
                  ? Icon(
                      icon,
                      color: Color(0xFFffffff),
                      size: 30,
                    )
                  : Icon(
                      icon,
                      color: Color(0xFFfafafa),
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final int selectedIndex;
  final int previousIndex;
  final double animationValue;
  final bool isDark;

  WavePainter({
    required this.selectedIndex,
    required this.previousIndex,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final itemWidth = size.width / 3;
    
    // Animasyonlu pozisyon hesaplama
    final previousX = (previousIndex * itemWidth) + (itemWidth / 2);
    final currentX = (selectedIndex * itemWidth) + (itemWidth / 2);
    final centerX = previousX + (currentX - previousX) * animationValue;
    
    final circleRadius = 25.0;
    final centerY = size.height / 2;
    final notchDepth = centerY - circleRadius + 12; // Çentik derinliği - ikonun içine girecek şekilde
    final notchWidth = circleRadius * 1.8; // Çentik genişliği (ikonu tam kapsayacak)

    // Siyah barı aktif ikonun etrafında kıvrılarak çiz
    final path = Path();
    
    // Sol üst köşe
    path.moveTo(0, 0);
    
    // Üst kenar - sol taraftan başla
    path.lineTo(centerX - notchWidth / 2, 0);
    
    // Çentik sol tarafı - içe doğru kıvrım (ikonun içine girecek şekilde)
    path.cubicTo(
      centerX - notchWidth / 2 + notchWidth * 0.15,
      0,
      centerX - notchWidth / 2 + notchWidth * 0.3,
      notchDepth * 0.3,
      centerX - notchWidth / 2 + notchWidth * 0.4,
      notchDepth * 0.6,
    );
    
    // Çentik tepe noktası - ikonun içine girecek şekilde (en derin nokta)
    path.cubicTo(
      centerX - notchWidth / 2 + notchWidth * 0.5,
      notchDepth,
      centerX - notchWidth / 2 + notchWidth * 0.6,
      notchDepth * 0.6,
      centerX - notchWidth / 2 + notchWidth * 0.7,
      notchDepth * 0.3,
    );
    
    // Çentik sağ tarafı - dışa doğru kıvrım (yumuşak geçiş)
    path.cubicTo(
      centerX - notchWidth / 2 + notchWidth * 0.85,
      0,
      centerX - notchWidth / 2 + notchWidth * 1.0,
      0,
      centerX + notchWidth / 2,
      0,
    );
    
    // Sağ üst köşe
    path.lineTo(size.width, 0);
    
    // Sağ kenar
    path.lineTo(size.width, size.height);
    
    // Alt kenar - düz çizgi (dalga yok)
    path.lineTo(0, size.height);
    
    // Sol kenar
    path.close();

    // Yuvarlatılmış köşeler için clip
    final roundedRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(30),
    );
    
    final clipPath = Path()..addRRect(roundedRect);
    final finalPath = Path.combine(
      PathOperation.intersect,
      path,
      clipPath,
    );

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.previousIndex != previousIndex ||
        oldDelegate.animationValue != animationValue;
  }
}

