import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Soft nature backdrop with organic blob shapes.
class NatureBackground extends StatelessWidget {
  const NatureBackground({super.key, required this.child, this.showBlobs = true});

  final Widget child;
  final bool showBlobs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [NatureColors.cream, NatureColors.mint, Color(0xFFDDEEE2)],
            ),
          ),
        ),
        if (showBlobs) ...[
          Positioned(
            top: -80,
            right: -60,
            child: _blob(180, NatureColors.leaf.withValues(alpha: 0.12)),
          ),
          Positioned(
            top: 120,
            left: -70,
            child: _blob(140, NatureColors.moss.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: 60,
            right: -40,
            child: _blob(120, NatureColors.sage.withValues(alpha: 0.15)),
          ),
        ],
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Gradient header bar for home and auth screens.
class NatureHeader extends StatelessWidget implements PreferredSizeWidget {
  const NatureHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 88 : 72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: NatureColors.gradientHero,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x331A5D3A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }
}

class NaturePrimaryButton extends StatelessWidget {
  const NaturePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

class NatureGlassCard extends StatelessWidget {
  const NatureGlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NatureColors.skyMist),
        boxShadow: [
          BoxShadow(
            color: NatureColors.forest.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
