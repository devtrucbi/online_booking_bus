import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.yellow, Colors.amber],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  // Logo
                  BounceInDown(
                    duration: const Duration(milliseconds: 800),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.black87,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tiêu đề
                  Expanded(
                    child: ZoomIn(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  // Actions
                  ...?actions
                          ?.map(
                            (action) => FadeInRight(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 400),
                              child: action,
                            ),
                          )
                          ?.toList() ??
                      [],
                ],
              ),
            ),
            if (bottom != null)
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: bottom!,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    const double paddingHeight = 8.0; // Top and bottom padding (4.0 + 4.0)
    const double contentHeight = 48.0; // Height of the Row
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(contentHeight + paddingHeight + bottomHeight);
  }
}
