import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../constants/app_colors.dart';

class SurahCard extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;
  final int? bookmarkCount;

  const SurahCard({
    super.key,
    required this.surah,
    required this.onTap,
    this.bookmarkCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildSurahNumber(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSurahName(),
                    const SizedBox(height: 4),
                    _buildSurahInfo(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildArrowIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahNumber() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Text(
          '${surah.number}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahName() {
    return Row(
      children: [
        Expanded(
          child: Text(
            surah.nameArabic,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          surah.nameEnglish,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSurahInfo() {
    return Row(
      children: [
        Text(
          surah.revelationType,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.textLight,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${surah.numberOfAyahs} verses',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
        if (bookmarkCount != null && bookmarkCount! > 0) ...[
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.textLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 2),
              Text(
                '$bookmarkCount',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildArrowIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.primary,
      ),
    );
  }
}
