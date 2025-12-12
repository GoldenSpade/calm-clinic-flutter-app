import 'package:flutter/material.dart';

class LessonsHeader extends StatelessWidget {
  const LessonsHeader({super.key});

  void _scrollToConstructor(BuildContext context) {
    // TODO: Implement scroll to constructor section
    // This will be implemented when we add the constructor section
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;
    final isSmallMobile = screenWidth <= 500;

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/lessons/header-bg.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: isMobile ? 40 : 60,
        ),
        child: Column(
          mainAxisAlignment: isMobile ? MainAxisAlignment.end : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Text(
                'Твоя внутрішня сила починається тут.',
                style: TextStyle(
                  fontSize: isMobile ? 32 : 68,
                  height: 1.2,
                  color: const Color(0xFFE3A644),
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  shadows: const [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 10,
                      color: Color(0x80000000),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 20 : 30),

            // Caption
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 15 : 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0x80000000),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Глибокі уроки, які допоможуть тобі зрозуміти себе, вийти з болю, відновити опору всередині та побудувати зрілі стосунки — з собою і з людьми.',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  height: 1.5,
                  color: const Color(0xFFDCB373),
                  fontFamily: 'Roboto Mono',
                  fontWeight: FontWeight.w400,
                  shadows: const [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Color(0x80000000),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 20 : 30),

            // Gold Button
            _buildGoldButton(context, isMobile, isSmallMobile),
            SizedBox(height: isMobile ? 10 : 15),

            // Microtext
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: EdgeInsets.fromLTRB(
                isMobile ? 15 : 25,
                10,
                20,
                10,
              ),
              decoration: BoxDecoration(
                color: const Color(0x80000000),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Доступ одразу після оплати · уроки в записі на 2 місяці · практики та тести всередині',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xD9DCB373),
                  fontFamily: 'Roboto Mono',
                  fontWeight: FontWeight.w300,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Color(0x99000000),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldButton(BuildContext context, bool isMobile, bool isSmallMobile) {
    return SizedBox(
      width: isSmallMobile ? double.infinity : null,
      child: InkWell(
        onTap: () => _scrollToConstructor(context),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 50 : 80,
            vertical: isMobile ? 15 : 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0x80000000),
            border: Border.all(
              color: const Color(0xFFDCB373),
              width: 4,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Top dot
              Positioned(
                top: -3,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD5BC94),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Bottom dot
              Positioned(
                bottom: -3,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD5BC94),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Button text
              Text(
                'ОБРАТИ СВІЙ УРОК',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFDCB373),
                  fontFamily: 'Roboto Mono',
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  shadows: const [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Color(0x80000000),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
