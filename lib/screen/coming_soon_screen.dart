import 'package:flutter/material.dart';

import '../utility/app_color.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String primaryActionText;

  const ComingSoonScreen({
    super.key,
    this.title = 'Coming soon',
    this.message = 'This feature is being prepared and will be available soon.',
    this.icon = Icons.construction_outlined,
    this.primaryActionText = 'Back',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColor.darkOrange,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColor.lightOrange.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: Icon(
                    icon,
                    size: 46,
                    color: AppColor.darkOrange,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.darkOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(primaryActionText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
