import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class LatestReportPage extends StatelessWidget {
  const LatestReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth * 0.92;
            return GlassmorphicContainer(
              width: maxWidth,
              height: 420,
              borderRadius: 32,
              blur: 18,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.black.withOpacity(0.15),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth - 56), // 28 padding each side
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SizedBox(height: 8),
                            Text(
                              'Latest Report',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 1.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              maxLines: 2,
                            ),
                            SizedBox(height: 24),
                            Text('Patient: John Doe', style: TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis, softWrap: true, maxLines: 2),
                            SizedBox(height: 10),
                            Text('Blood Pressure: 120/80 mmHg', style: TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis, softWrap: true, maxLines: 2),
                            SizedBox(height: 10),
                            Text('Diagnosis: Hypertension', style: TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis, softWrap: true, maxLines: 2),
                            SizedBox(height: 10),
                            Text('Date: 2024-06-01', style: TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis, softWrap: true, maxLines: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 