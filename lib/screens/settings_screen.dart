import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/translation_provider.dart';
import '../providers/quran_data_provider.dart';
import '../providers/audio_provider.dart';
import '../services/local_storage_service.dart';
import '../services/toast_service.dart';
import '../constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Appearance',
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: AppColors.primary,
                    ),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Toggle dark/light theme'),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) => themeProvider.toggleTheme(),
                      activeColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Audio',
            children: [
              ListTile(
                leading: const Icon(Icons.volume_up, color: AppColors.primary),
                title: const Text('Audio Quality'),
                subtitle: const Text('High quality recitation'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: AppColors.primary),
                title: const Text('Playback Speed'),
                subtitle: const Text('1.0x'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              Consumer<AudioProvider>(
                builder: (context, audioProvider, child) {
                  return FutureBuilder<Map<String, dynamic>>(
                    future: audioProvider.getAudioCacheStats(),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {'totalFiles': 0, 'totalSize': 0, 'usagePercentage': 0};
                      final totalSizeMB = (stats['totalSize'] as int) / (1024 * 1024);
                      
                      return ListTile(
                        leading: const Icon(Icons.offline_pin, color: AppColors.primary),
                        title: const Text('Audio Cache'),
                        subtitle: Text('${stats['totalFiles']} files, ${totalSizeMB.toStringAsFixed(1)} MB'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${stats['usagePercentage']}%',
                              style: TextStyle(
                                color: stats['usagePercentage'] > 80 ? Colors.orange : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () => _showAudioCacheDialog(context, audioProvider),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Text',
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields, color: AppColors.primary),
                title: const Text('Font Size'),
                subtitle: const Text('Medium'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              Consumer<TranslationProvider>(
                builder: (context, translationProvider, child) {
                  final selectedLanguage = translationProvider.selectedLanguage;
                  final languageName = translationProvider.availableLanguages[selectedLanguage] ?? selectedLanguage;
                  
                  return ListTile(
                    leading: const Icon(Icons.translate, color: AppColors.primary),
                    title: const Text('Translation Language'),
                    subtitle: Text(languageName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showLanguageSelectionDialog(context, translationProvider),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Storage',
            children: [
              Consumer<QuranDataProvider>(
                builder: (context, quranProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.storage, color: AppColors.primary),
                    title: const Text('Offline Mode'),
                    subtitle: Text(quranProvider.isOfflineMode ? 'Currently offline' : 'Online mode'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: quranProvider.isOfflineMode ? Colors.orange : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quranProvider.isOfflineMode ? 'OFFLINE' : 'ONLINE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.primary),
                title: const Text('Clear Cache'),
                subtitle: const Text('Remove all offline data'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showClearCacheDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.primary),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context, TranslationProvider translationProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Translation Language'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: translationProvider.availableLanguages.length,
              itemBuilder: (context, index) {
                final languageCode = translationProvider.availableLanguages.keys.elementAt(index);
                final languageName = translationProvider.availableLanguages[languageCode]!;
                final isSelected = languageCode == translationProvider.selectedLanguage;

                return ListTile(
                  title: Text(languageName),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    translationProvider.setLanguage(languageCode);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text(
            'This will remove all offline data including surahs, ayahs, and translations. '
            'You will need an internet connection to reload the data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearCache(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    try {
      final localStorage = await LocalStorageService.getInstance();
      await localStorage.clearCache();
      
      // Clear the provider data
      if (context.mounted) {
        final quranProvider = context.read<QuranDataProvider>();
        quranProvider.clearCache();
        
        ToastService.showSuccess('Cache cleared successfully');
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError('Failed to clear cache: $e');
      }
    }
  }

  void _showAudioCacheDialog(BuildContext context, AudioProvider audioProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Audio Cache Management'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: audioProvider.getAudioCacheStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final stats = snapshot.data ?? {'totalFiles': 0, 'totalSize': 0, 'usagePercentage': 0};
              final totalSizeMB = (stats['totalSize'] as int) / (1024 * 1024);
              final maxSizeMB = (stats['maxSize'] as int) / (1024 * 1024);
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cached Files: ${stats['totalFiles']}'),
                  const SizedBox(height: 8),
                  Text('Total Size: ${totalSizeMB.toStringAsFixed(1)} MB / ${maxSizeMB.toStringAsFixed(1)} MB'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: stats['usagePercentage'] / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stats['usagePercentage'] > 80 ? Colors.orange : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Audio files are automatically downloaded when you play them for the first time. '
                    'They are stored locally for offline playback.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await audioProvider.clearAudioCache();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear Cache'),
            ),
          ],
        );
      },
    );
  }
}
