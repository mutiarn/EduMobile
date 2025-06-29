// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mobile_edu/auth/login_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:slide_to_act/slide_to_act.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final Color primaryColor = const Color(0xFF6366f1);
  final Color secondaryColor = const Color(0xFF8b5cf6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.05),
              secondaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            // PageView content
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                _buildWelcomePage(
                  // illustration: _buildTrackingIllustration(),
                  title: "Track Your Progress",
                  description:
                      "Monitor your learning journey and\nearn certificates as you advance",
                ),
                _buildWelcomePage(
                  // illustration: _buildLearningIllustration(),
                  title: "Interactive Learning",
                  description:
                      "Engage with hands-on projects\nand practical exercises",
                ),
                _buildWelcomePage(
                  // illustration: _buildCommunityIllustration(),
                  title: "Learn Together",
                  description:
                      "Connect with expert instructors\nand fellow learners",
                ),
                _buildWelcomePage(
                  // illustration: _buildSuccessIllustration(),
                  title: "Start Your Journey",
                  description:
                      "Unlock endless learning opportunities\nand achieve your goals",
                  isLastPage: true,
                ),
              ],
            ),

            if (_currentIndex < 3)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: 4,
                    effect: WormEffect(
                      dotColor: const Color.fromARGB(255, 255, 255, 255),
                      activeDotColor: primaryColor,
                      dotHeight: 10,
                      dotWidth: 10,
                      spacing: 16,
                    ),
                  ),
                ),
              ),

            if (_currentIndex < 3)
              Positioned(
                bottom: 40,
                right: 32,
                child: GestureDetector(
                  onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage({
    required String title,
    required String description,
    bool isLastPage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          const SizedBox(height: 200),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Slide button for last page
          if (isLastPage)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 50),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SlideAction(
                height: 64,
                borderRadius: 32,
                elevation: 0,
                sliderButtonYOffset: -2,
                submittedIcon: const Icon(
                  Icons.check,
                  color: Color(0xFF6B73FF),
                  size: 24,
                ),
                text: 'Slide to Start Learning',
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                outerColor: primaryColor,
                innerColor: Colors.white,
                sliderButtonIcon: const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF6B73FF),
                  size: 24,
                ),
                sliderRotate: false,
                animationDuration: const Duration(milliseconds: 300),
                onSubmit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                  return null;
                },
              ),
            ),

          if (!isLastPage) const SizedBox(height: 120),
        ],
      ),
    );
  }
}