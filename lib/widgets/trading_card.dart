import 'package:flutter/material.dart';

import '../models/card.dart';
import 'battle_feedback.dart';
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
    this.owned = true,
    this.hpOverride,
  }) : assert(faceDown || data != null, 'data is required for a face-up card');

  final GameCard? data;
  final double width;
  final bool faceDown;

  /// Whether the player owns this card. Only matters for face-up
  /// cards (e.g. in the collection) — cards shown face-down don't
  /// need an ownership look. Defaults to true so existing call sites
  /// (deck builder, game board) don't need to pass it.
  final bool owned;

  /// Shows this instead of the card's base HP — used on the game
  /// board, where a card's current HP can be lower than its base HP
  /// after taking damage. Defaults to null, which shows the card's
  /// own `hp` (its starting/max value).
  final int? hpOverride;

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
    final cardWidget = _buildFaceUpCard(card, width, height);

    if (!owned) {
      return _UnownedCardOverlay(
        width: width,
        height: height,
        child: cardWidget,
      );
    }
    return cardWidget;
  }

  Widget _buildFaceUpCard(GameCard card, double width, double height) {
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
                _CostBadge(cost: card.attackCost, size: width * 0.2),
              ],
            ),
            Text(
              card.cardType.label.toUpperCase(),
              style: TextStyle(
                fontSize: width * 0.065,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _CardArtwork(path: card.artwork, iconSize: width * 0.35),
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
                  AnimatedHp(hp: hpOverride ?? card.hp),
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

/// Wraps an owned-looking card to show it as locked/not-owned:
/// grayed out, dimmed, and tagged with a lock icon and label so it's
/// unmistakably different from a card the player actually has.
class _UnownedCardOverlay extends StatelessWidget {
  const _UnownedCardOverlay({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  // Standard luminance-based grayscale matrix.
  static const List<double> _grayscaleMatrix = [
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
            child: Opacity(opacity: 0.55, child: child),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.lock,
              size: width * 0.32,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkForestGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'NOT OWNED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: (width * 0.075).clamp(8.0, 13.0),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a card's artwork image, cropped/scaled to fill its box so
/// every card looks consistent no matter the source image's size.
/// Falls back to a generic icon if there's no artwork path yet, or if
/// the asset fails to load (e.g. a typo'd path), so a missing image
/// never crashes the app.
class _CardArtwork extends StatelessWidget {
  const _CardArtwork({required this.path, required this.iconSize});

  final String path;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return _placeholder();
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.forestGreen.withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: AppColors.earthBrown.withValues(alpha: 0.5),
        ),
      ),
    );
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
