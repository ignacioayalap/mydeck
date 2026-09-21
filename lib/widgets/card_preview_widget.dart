import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/card_item.dart';
import 'foil_shimmer_effect.dart';

class CardPreviewWidget extends StatelessWidget {
  final CardItem card;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFoil;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;
  final bool showControls;

  const CardPreviewWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onToggleFoil,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
    this.showControls = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: card.isFoil ? AppColors.foilAmber : AppColors.border,
            width: card.isFoil ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: card.isFoil
                  ? AppColors.foilGold.withOpacity(0.2)
                  : Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Image with Foil Effect
            Expanded(
              child: FoilShimmerEffect(
                isFoil: card.isFoil,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: Container(
                  width: double.infinity,
                  color: AppColors.surfaceLight,
                  child: card.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: card.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.broken_image, color: AppColors.textMuted),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.style, size: 40, color: AppColors.textMuted),
                        ),
                ),
              ),
            ),

            // Card Metadata
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.typeLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price badge and foil toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.formatUsd(card.currentPriceUsd),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: card.isFoil ? AppColors.foilGold : AppColors.success,
                            ),
                          ),
                          Text(
                            Formatters.formatEur(card.currentPriceEur),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (onToggleFoil != null)
                        InkWell(
                          onTap: onToggleFoil,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: card.isFoil
                                  ? AppColors.foilGold.withOpacity(0.2)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: card.isFoil ? AppColors.foilGold : AppColors.border,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: card.isFoil ? AppColors.foilGold : AppColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Quantity Controls (if in deck mode)
                  if (showControls) ...[
                    const Divider(height: 12, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: onDecrement,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${card.quantity}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: onIncrement,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.add, size: 14, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        if (onRemove != null)
                          InkWell(
                            onTap: onRemove,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
