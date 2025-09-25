import 'package:flutter/material.dart';

class AppBrand extends StatelessWidget {
  final double height;
  final bool showText;

  const AppBrand({super.key, this.height = 28, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'assets/icons/EKIBAM.jpg',
            height: height,
            width: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return Container(
                height: height,
                width: height,
                color: color.withValues(alpha: 0.1),
                alignment: Alignment.center,
                child: Icon(Icons.store, color: color, size: height * 0.7),
              );
            },
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'ekibam',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ]
      ],
    );
  }
}
