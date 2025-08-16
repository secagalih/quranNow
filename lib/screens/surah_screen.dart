import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../providers/quran_data_provider.dart';
import '../providers/translation_provider.dart';
import '../models/surah.dart';
import '../constants/app_colors.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom_error;

class SurahScreen extends StatefulWidget {
  final int surahId;

  const SurahScreen({
    super.key,
    required this.surahId,
  });

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quranProvider = context.read<QuranDataProvider>();
      final translationProvider = context.read<TranslationProvider>();
      quranProvider.loadAyahs(widget.surahId, translationProvider: translationProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<QuranDataProvider, TranslationProvider>(
        builder: (context, quranProvider, translationProvider, child) {
          if (quranProvider.isLoading) {
            return const LoadingWidget();
          }

          if (quranProvider.error != null) {
            return custom_error.CustomErrorWidget(
              message: quranProvider.error!,
              onRetry: () {
                quranProvider.loadAyahs(widget.surahId, translationProvider: translationProvider);
              },
            );
          }

          final ayahs = quranProvider.getAyahs(widget.surahId);
          if (ayahs.isEmpty) {
            return const Center(
              child: Text('No verses found'),
            );
          }

          return Column(
            children: [
              _buildSurahHeader(quranProvider),
              Expanded(
                child: _buildAyahList(ayahs, quranProvider, translationProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSurahHeader(QuranDataProvider quranProvider) {
    final surah = quranProvider.surahs.firstWhere(
      (s) => s.number == widget.surahId,
      orElse: () => Surah(
        number: widget.surahId,
        name: 'Surah $widget.surahId',
        nameArabic: '',
        nameEnglish: '',
        revelationType: '',
        numberOfAyahs: 0,
        description: '',
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Back button and content row
          Row(
            children: [

              Expanded(
                child: Column(
                  children: [
                                         // Arabic name
                     Stack(
                       children: [
                         // Centered surah names
                         Center(
                           child: Column(
                             children: [
                               Text(
                                 surah.nameArabic,
                                 style: const TextStyle(
                                   fontSize: 18,
                                   fontWeight: FontWeight.bold,
                                   color: Colors.white,
                                   fontFamily: 'Uthmanic',
                                 ),
                                 textAlign: TextAlign.center,
                                 textDirection: TextDirection.rtl,
                               ),
                               const SizedBox(height: 2),
                               // Latin name
                               Text(
                                 surah.nameEnglish,
                                 style: const TextStyle(
                                   fontSize: 11,
                                   fontWeight: FontWeight.w600,
                                   color: Colors.white,
                                   fontStyle: FontStyle.italic,
                                 ),
                                 textAlign: TextAlign.center,
                               ),
                             ],
                           ),
                         ),
                         // Back button positioned on the left
                         Positioned(
                           left: 0,
                           top: 0,
                           child: IconButton(
                             onPressed: () => context.pop(),
                             icon: const Icon(
                               Icons.arrow_back_ios,
                               color: Colors.white,
                               size: 16,
                             ),
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                           ),
                         ),
                         // Language selector positioned on the right
                         Positioned(
                           right: 0,
                           top: 13,
                           child: Consumer<TranslationProvider>(
                             builder: (context, translationProvider, child) {
                               return PopupMenuButton<String>(
                                 padding: EdgeInsets.zero,
                                 constraints: const BoxConstraints(),
                                 onSelected: (languageCode) {
                                   translationProvider.setLanguage(languageCode);
                                   // Reload ayahs with new translation
                                   quranProvider.loadAyahs(widget.surahId, translationProvider: translationProvider);
                                 },
                                 itemBuilder: (context) {
                                   return translationProvider.availableLanguages.entries.map((entry) {
                                     final isSelected = translationProvider.selectedLanguage == entry.key;
                                     return PopupMenuItem<String>(
                                       value: entry.key,
                                       child: Row(
                                         children: [
                                           Text(
                                             entry.value,
                                             style: TextStyle(
                                               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                             ),
                                           ),
                                           if (isSelected) ...[
                                             const Spacer(),
                                             const Icon(Icons.check, size: 16),
                                           ],
                                         ],
                                       ),
                                     );
                                   }).toList();
                                 },
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   decoration: BoxDecoration(
                                     color: Colors.white.withValues(alpha: 0.2),
                                     borderRadius: BorderRadius.circular(12),
                                     border: Border.all(
                                       color: Colors.white.withValues(alpha: 0.3),
                                       width: 1,
                                     ),
                                   ),
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       const Icon(
                                         Icons.language,
                                         color: Colors.white,
                                         size: 14,
                                       ),
                                       const SizedBox(width: 4),
                                       Text(
                                         translationProvider.availableLanguages[translationProvider.selectedLanguage] ?? 'EN',
                                         style: const TextStyle(
                                           color: Colors.white,
                                           fontSize: 12,
                                           fontWeight: FontWeight.w600,
                                         ),
                                       ),
                                       const SizedBox(width: 2),
                                       const Icon(
                                         Icons.arrow_drop_down,
                                         color: Colors.white,
                                         size: 16,
                                       ),
                                     ],
                                   ),
                                 ),
                               );
                             },
                           ),
                         ),
                       ],
                     ),
                    const SizedBox(height: 4),
                    // Surah details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSurahDetail('Ayat', '${surah.numberOfAyahs}'),
                        _buildSurahDetail('Type', surah.revelationType),
                        _buildSurahDetail('Number', '${surah.number}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurahDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAyahList(List ayahs, QuranDataProvider quranProvider, TranslationProvider translationProvider) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ayahs.length,
        itemBuilder: (context, index) {
          final ayah = ayahs[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildAyahCard(ayah, index + 1, quranProvider, translationProvider),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAyahCard(dynamic ayah, int ayahNumber, QuranDataProvider quranProvider, TranslationProvider translationProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAyahHeader(ayahNumber),
            const SizedBox(height: 16),
            _buildAyahText(ayah, quranProvider),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahHeader(int ayahNumber) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$ayahNumber',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.bookmark_border),
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildAyahText(dynamic ayah, QuranDataProvider quranProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Arabic text (from EQuran.id API)
          Text(
            ayah.text ?? '',
            style: const TextStyle(
              fontSize: 20,
              height: 2.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Uthmanic',
            ),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          // Latin text (from EQuran.id API)
          if (ayah.translations['latin'] != null && ayah.translations['latin']!.isNotEmpty)
            Text(
              ayah.translations['latin']!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
            ),
          const SizedBox(height: 8),
          // Translation (from current translation API)
          Consumer<TranslationProvider>(
            builder: (context, translationProvider, child) {
              final selectedLang = translationProvider.selectedLanguage;
              final translations = quranProvider.getTranslations(widget.surahId, ayah.number);
              final translation = translations[selectedLang] ?? '';

              if (translation.isNotEmpty) {
                return Text(
                  translation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.6,
                        fontSize: 15,
                      ),
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.ltr,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
