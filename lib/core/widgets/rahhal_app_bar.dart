import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rahal/core/theme/app_theme.dart';

/// Reusable role-aware AppBar that prevents white-on-white text/icon bugs.
/// Automatically handles light and dark mode contrasts, back navigation,
/// and tab-switching fallback.
class RahhalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleText;
  final Widget? titleWidget;
  final String? subtitleText;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  const RahhalAppBar({
    super.key,
    this.titleText,
    this.titleWidget,
    this.subtitleText,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.bottom,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBg = backgroundColor ??
        (isDark ? theme.colorScheme.surface : theme.colorScheme.surface);

    final resolvedFg = foregroundColor ??
        (isDark ? Colors.white : AppTheme.primaryColor);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: resolvedFg,
        tooltip: 'رجوع',
        onPressed: () {
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback: Return to home/dashboard if embedded without pop stack
              context.go('/dashboard');
            }
          }
        },
      );
    }

    Widget? finalTitle;
    if (titleWidget != null) {
      finalTitle = titleWidget;
    } else if (titleText != null) {
      if (subtitleText != null && subtitleText!.isNotEmpty) {
        finalTitle = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              titleText!,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: resolvedFg,
              ),
            ),
            Text(
              subtitleText!,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: resolvedFg.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      } else {
        finalTitle = Text(
          titleText!,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: resolvedFg,
          ),
        );
      }
    }

    return AppBar(
      backgroundColor: resolvedBg,
      foregroundColor: resolvedFg,
      elevation: elevation,
      centerTitle: centerTitle,
      leading: leadingWidget,
      title: finalTitle,
      actions: actions,
      bottom: bottom,
      iconTheme: IconThemeData(color: resolvedFg),
      actionsIconTheme: IconThemeData(color: resolvedFg),
    );
  }
}
