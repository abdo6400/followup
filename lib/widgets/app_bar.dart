import 'package:flutter/material.dart';
import 'package:followup/utils/constants.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? titleSpacing;
  final double toolbarHeight;
  final PreferredSizeWidget? bottom;
  final double bottomHeight;
  final VoidCallback? onBackPressed;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.titleSpacing,
    this.toolbarHeight = kToolbarHeight,
    this.bottom,
    this.bottomHeight = kToolbarHeight,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: foregroundColor ?? theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: leading ?? _buildBackButton(context, isDark),
      actions: actions,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      foregroundColor: foregroundColor ?? theme.colorScheme.onSurface,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
      bottom: bottom,
      shape: const Border(
        bottom: BorderSide(
          color: AppColors.divider,
          width: 1.0,
        ),
      ),
    );
  }

  Widget? _buildBackButton(BuildContext context, bool isDark) {
    if (!automaticallyImplyLeading) return null;
    
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (!canPop) return null;
    
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
      onPressed: onBackPressed ?? () => Navigator.maybePop(context),
      padding: const EdgeInsets.all(16),
      splashRadius: 24,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom != null ? bottomHeight : 0),
      );
}

class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color? backgroundColor;

  const SliverAppBarDelegate({
    required this.child,
    required this.height,
    this.backgroundColor,
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return height != oldDelegate.height ||
        child != oldDelegate.child ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
