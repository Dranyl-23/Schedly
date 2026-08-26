import 'package:flutter/material.dart';
import '../../../models/institution_directory.dart';

class InstitutionLogo extends StatelessWidget {
  final InstitutionItem item;
  final double size;

  const InstitutionLogo({
    super.key,
    required this.item,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content;
    if (item.assetLogo.isNotEmpty) {
      content = Image.asset(
        item.assetLogo,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallback(isDark),
      );
    } else if (item.logoUrl.isNotEmpty) {
      content = Image.network(
        item.logoUrl,
        fit: BoxFit.contain,
        headers: const {'User-Agent': 'Mozilla/5.0 (Android; Mobile)'},
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildFallback(isDark);
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(isDark),
      );
    } else {
      content = _buildFallback(isDark);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(3.5),
      child: content,
    );
  }

  Widget _buildFallback(bool isDark) {
    final initials = item.emblemInitials.isNotEmpty
        ? item.emblemInitials
        : (item.shortName.length > 5 ? item.shortName.substring(0, 4) : item.shortName);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item.themeColor.withValues(alpha: 0.18),
            item.themeColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: initials.isNotEmpty && initials.length <= 6
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    initials,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w900,
                      color: item.themeColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              )
            : Icon(
                item.icon,
                color: item.themeColor,
                size: size * 0.52,
              ),
      ),
    );
  }
}
