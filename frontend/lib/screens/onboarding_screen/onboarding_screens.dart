import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:frontend/screens/auth_screens/login_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFE8F5E9).withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Animated background circles
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Positioned(
                  top: 100 + (index * 200.0) - (_fadeController.value * 50),
                  right: -100 + (index * 50.0),
                  child: Opacity(
                    opacity: 0.05 + (_fadeController.value * 0.05),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF66BB6A).withOpacity(0.3),
                            const Color(0xFF66BB6A).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                if (_currentPage < 2)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextButton(
                        onPressed: _skipToEnd,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF66BB6A),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 56),
                // Page view
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: const [
                      OnboardingPage1(),
                      OnboardingPage2(),
                      OnboardingPage3(),
                    ],
                  ),
                ),
                // Page indicator and button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Column(
                    children: [
                      // Page dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? const Color(0xFF66BB6A)
                                  : const Color(0xFF66BB6A).withOpacity(0.2),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF66BB6A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentPage == 2 ? 'Get Started' : 'Continue',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Page 1: Track Your Cravings
class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({Key? key}) : super(key: key);

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height - 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isSmallScreen ? 20 : 40),
              // Animated illustration
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      math.sin(_controller.value * 2 * math.pi) * 10,
                    ),
                    child: Container(
                      width: isSmallScreen ? 200 : 240,
                      height: isSmallScreen ? 200 : 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: isSmallScreen ? 160 : 190,
                          height: isSmallScreen ? 160 : 190,
                          decoration: const BoxDecoration(
                            color: Color(0xFF66BB6A),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: isSmallScreen ? 70 : 90,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isSmallScreen ? 32 : 48),
              // Title
              Text(
                'Track Your\nCravings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 32 : 38,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: const Color(0xFF1B5E20),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Every craving tells a story. We help you understand yours and make smarter choices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    height: 1.5,
                    color: const Color(0xFF1B5E20).withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 2: Smart Alternatives
class OnboardingPage2 extends StatefulWidget {
  const OnboardingPage2({Key? key}) : super(key: key);

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final cardWidth = isSmallScreen ? 130.0 : 150.0;
    final cardHeight = isSmallScreen ? 170.0 : 190.0;
    final iconSize = isSmallScreen ? 55.0 : 65.0;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height - 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isSmallScreen ? 20 : 40),
              // Animated swap illustration
              SizedBox(
                height: isSmallScreen ? 220 : 250,
                child: Stack(
                  children: [
                    // "Bad" food card
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(-_controller.value * 100, 0),
                          child: Opacity(
                            opacity: 1 - _controller.value,
                            child: Container(
                              width: cardWidth,
                              height: cardHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF5350).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFEF5350),
                                  width: 2.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fastfood_rounded,
                                    size: iconSize,
                                    color: const Color(0xFFEF5350),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Craving',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 17,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEF5350),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Arrow
                    Positioned(
                      left: 0,
                      right: 0,
                      top: isSmallScreen ? 75 : 85,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1 + (_controller.value * 0.3),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: isSmallScreen ? 40 : 45,
                                color: const Color(0xFF66BB6A),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // "Good" food card
                    Positioned(
                      right: 0,
                      top: isSmallScreen ? 30 : 35,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_controller.value * 100, 0),
                            child: Opacity(
                              opacity: _controller.value,
                              child: Container(
                                width: cardWidth,
                                height: cardHeight,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF66BB6A,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF66BB6A),
                                    width: 2.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.eco_rounded,
                                      size: iconSize,
                                      color: const Color(0xFF66BB6A),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Healthier',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 17,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF66BB6A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 32 : 48),
              // Title
              Text(
                'Discover Smart\nAlternatives',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 32 : 38,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: const Color(0xFF1B5E20),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Get personalized healthier options that satisfy your cravings without the guilt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    height: 1.5,
                    color: const Color(0xFF1B5E20).withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 3: Earn Your Treats
class OnboardingPage3 extends StatefulWidget {
  const OnboardingPage3({Key? key}) : super(key: key);

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final circleSize = isSmallScreen ? 110.0 : 130.0;
    final iconSize = isSmallScreen ? 55.0 : 65.0;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height - 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isSmallScreen ? 20 : 40),
              // Exercise reward illustration
              SizedBox(
                height: isSmallScreen ? 220 : 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress circles
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final delay = index * 0.3;
                          final progress = (_controller.value + delay) % 1.0;
                          final maxSize = isSmallScreen ? 140.0 : 150.0;
                          return Opacity(
                            opacity: 1 - progress,
                            child: Container(
                              width: circleSize - 10 + (progress * maxSize),
                              height: circleSize - 10 + (progress * maxSize),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF66BB6A),
                                  width: 2.5,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    // Center icon
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFF66BB6A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_run_rounded,
                        size: iconSize,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 32 : 48),
              // Title
              Text(
                'Earn Your\nTreats',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 32 : 38,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: const Color(0xFF1B5E20),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Quick exercises tailored to your cravings. Balance indulgence with activity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    height: 1.5,
                    color: const Color(0xFF1B5E20).withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 40),
            ],
          ),
        ),
      ),
    );
  }
}
