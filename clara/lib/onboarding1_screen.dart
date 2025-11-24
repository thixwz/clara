import 'package:flutter/material.dart';
import 'package:clara/auth_screen.dart'; // Added import for AuthScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Welcome to Clara',
      subtitle: 'Analyze your reports and prescriptions with clara!',
    ),
    _OnboardingPageData(
      title: 'Use Clara to know more about your health',
      subtitle: 'Clara could understand and analyse the reports',
    ),
    _OnboardingPageData(
      title: 'Always use with caution',
      subtitle: 'you should always proceed with caution with the health details',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation = Tween<Offset>(
              begin: Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            // Page indicator (simple dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentPage == index ? (isDarkMode ? Colors.white : Colors.black) : (isDarkMode ? Colors.white24 : Colors.black26),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
            const SizedBox(height: 48),
            // Title and subtitle
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        page.title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          page.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF232323) : Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _prevPage,
                        child: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                  if (_currentPage > 0) const Spacer(),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF444444) : Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _nextPage,
                        child: Text(
                          _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : _currentPage == 1
                              ? 'Continue'
                              : 'Continue',
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
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
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
  });
} 