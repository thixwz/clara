import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'package:flutter/cupertino.dart';

class Onboarding2Screen extends StatelessWidget {
  const Onboarding2Screen({super.key});

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
            const SizedBox(height: 24),
            // Page indicator (provided image)
            Center(
              child: Image.asset(
                'assets/page_indicator_2.png',
                width: 100,
                height: 12,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            // Illustration placeholder
            Expanded(
              child: Center(
                child: Container(
                  width: 220,
                  height: 220,
                  color: isDarkMode ? Colors.white12 : Colors.grey[200],
                  child: const Icon(Icons.chat_bubble_outline, size: 120, color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title and subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Let’s talk!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Upload your prescriptions and chat with Clara for personalized support.',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Row(
                children: [
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
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                  const Spacer(),
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
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(builder: (context) => const AuthScreen()),
                          );
                        },
                        child: Text(
                          'Continue Now',
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