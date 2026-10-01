import 'package:flutter/material.dart';

import '../data/placeholder_cards.dart';
import '../theme/app_theme.dart';

/// Visual representation of a single trading card. Used in the
/// collection, deck builder, and game board screens so every card
/// looks the same everywhere in the app. Artwork is a plain
/// placeholder icon until real card art is added.
class TradingCardView extends StatelessWidget {
  const TradingCardView({
    super.key,
    this.data,
    this.width = 130,
    this.faceDown = false,
  }) : assert(faceDown || data != null, 'data is required for a face-up card');

  final PlaceholderCardData? data;
  final double width;
  final bool faceDown;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;

    if (faceDown) {
      return _CardFrame(
        width: width,
        height: height,
        borderColor: AppColors.earthBrown,
        backgroundColor: AppColors.darkForestGreen,
        child: Center(
          child: Icon(Icons.pets, size: width * 0.4, color: Colors.white70),
        ),
      );
    }

    final card = data!;
    final rarityColor = _rarityColor(card.rarity);
    final showDescription = width >= 110;

    return _CardFrame(
      width: width,
      height: height,
      borderColor: rarityColor,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.1,
                    ),
                  ),
                ),
                _CostBadge(cost: card.cost, size: width * 0.2),
              ],
            ),
            Text(
              card.cardType.toUpperCase(),
              style: TextStyle(
                fontSize: width * 0.065,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: width * 0.35,
                    color: AppColors.earthBrown.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            if (showDescription) ...[
              const SizedBox(height: 4),
              Text(
                card.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: width * 0.07, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatBadge(
                    icon: Icons.favorite,
                    value: card.hp,
                    color: Colors.redAccent,
                    fontSize: width * 0.1,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    icon: Icons.bolt,
                    value: card.attack,
                    color: Colors.orange,
                    fontSize: width * 0.1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return AppColors.rarityCommon;
      case CardRarity.uncommon:
        return AppColors.rarityUncommon;
      case CardRarity.rare:
        return AppColors.rarityRare;
      case CardRarity.legendary:
        return AppColors.rarityLegendary;
    }
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.width,
    required this.height,
    required this.borderColor,
    required this.child,
    this.backgroundColor,
  });

  final double width;
  final double height;
  final Color borderColor;
  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CostBadge extends StatelessWidget {
  const _CostBadge({required this.cost, required this.size});

  final int cost;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.goldAccent,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$cost',
        style: TextStyle(
          fontSize: size * 0.55,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.color,
    required this.fontSize,
  });

  final IconData icon;
  final int value;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: fontSize * 1.2, color: color),
        const SizedBox(width: 2),
        Text(
          '$value',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
