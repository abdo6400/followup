import 'package:flutter/material.dart';
import 'primary_button.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;
  final double iconSize;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final bool showIcon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.iconSize = 48.0,
    this.spacing = 16.0,
    this.padding,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIcon) ...[
              Icon(
                icon ?? Icons.error_outline_rounded,
                size: iconSize,
                color: theme.colorScheme.error.withOpacity(0.7),
              ),
              SizedBox(height: spacing),
            ],
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing / 2),
            ],
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: spacing),
              PrimaryButton(
                onPressed: onRetry,
                text: 'Retry',
                width: 120,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AsyncErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final String? message;
  final bool showStacktrace;

  const AsyncErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.message,
    this.showStacktrace = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = message ?? 'An error occurred: ${error.toString()}';
    
    return AppErrorWidget(
      message: errorMessage,
      title: 'Something went wrong',
      onRetry: onRetry,
      icon: Icons.error_outline_rounded,
    );
  }
}
