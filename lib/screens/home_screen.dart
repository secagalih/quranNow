import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:async';

import '../providers/quran_data_provider.dart';
import '../providers/bookmark_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/surah_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom_error;
import '../services/toast_service.dart';
import '../services/error_message_service.dart';
import '../utils/network_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  bool _isOnline = true;
  Timer? _networkCheckTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any previous errors when returning to home screen
      context.read<QuranDataProvider>().clearAllErrors();
      context.read<QuranDataProvider>().loadSurahs();
    });
    _startNetworkMonitoring();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear errors when screen becomes visible (e.g., when navigating back)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<QuranDataProvider>().clearAllErrors();
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _networkCheckTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startNetworkMonitoring() {
    // Check network status immediately
    _checkNetworkStatus();
    
    // Set up periodic network checking
    _networkCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkNetworkStatus();
    });
  }

  Future<void> _checkNetworkStatus() async {
    final hasInternet = await NetworkUtils.hasInternetConnection();
    if (mounted && _isOnline != hasInternet) {
      setState(() {
        _isOnline = hasInternet;
      });
      
      // Show toast notification for status change
      if (!hasInternet) {
        ToastService.showWarning('You are now offline');
      } else {
        ToastService.showSuccess('You are back online');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // All Surahs Tab
                    Consumer<QuranDataProvider>(
                      builder: (context, quranProvider, child) {
                        if (quranProvider.isLoading) {
                          return const LoadingWidget();
                        }

                        if (quranProvider.error != null) {
                          final errorInfo = ErrorMessageService.getErrorInfo(quranProvider.error!, context: 'home');
                          return custom_error.CustomErrorWidget(
                            title: errorInfo.title,
                            message: errorInfo.message,
                            subtitle: errorInfo.subtitle,
                            icon: errorInfo.icon,
                            retryButtonText: errorInfo.retryText,
                            onRetry: () => quranProvider.loadSurahs(),
                          );
                        }

                        return _buildSurahList(quranProvider);
                      },
                    ),
                    // Bookmarked Tab
                    Consumer2<QuranDataProvider, BookmarkProvider>(
                      builder: (context, quranProvider, bookmarkProvider, child) {
                        if (bookmarkProvider.isLoading) {
                          return const LoadingWidget();
                        }

                        if (!bookmarkProvider.hasBookmarks()) {
                          return _buildEmptyBookmarks();
                        }

                        return _buildBookmarkedSurahs(quranProvider, bookmarkProvider);
                      },
                    ),
                  ],
                ),
              ),
              // Network status indicator at bottom
              _buildNetworkStatusIndicator(),
            ],
          ),
        ),
      ),

    );
  }



  Widget _buildEmptyBookmarks() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Bookmarked Surahs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start bookmarking your favorite surahs and ayahs to see them here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkedSurahs(QuranDataProvider quranProvider, BookmarkProvider bookmarkProvider) {
    final bookmarks = bookmarkProvider.getBookmarksByDate();
    final bookmarkedSurahs = <int>{};
    
    // Get unique surah numbers from bookmarks
    for (final bookmark in bookmarks) {
      bookmarkedSurahs.add(bookmark.surahNumber);
    }

    // Filter surahs that have bookmarks
    final surahsWithBookmarks = quranProvider.surahs
        .where((surah) => bookmarkedSurahs.contains(surah.number))
        .toList();

    if (surahsWithBookmarks.isEmpty) {
      return _buildEmptyBookmarks();
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: surahsWithBookmarks.length,
        itemBuilder: (context, index) {
          final surah = surahsWithBookmarks[index];
          final bookmarkCount = bookmarkProvider.getBookmarkCountForSurah(surah.number);
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: SurahCard(
                    surah: surah,
                    onTap: () => context.push('/surah/${surah.number}'),
                    bookmarkCount: bookmarkCount,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkStatusIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: _isOnline ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: _isOnline ? Colors.green.shade700 : Colors.orange.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Consumer<QuranDataProvider>(
            builder: (context, quranProvider, child) {
              if (quranProvider.isOfflineMode && _isOnline) {
                return TextButton(
                  onPressed: () async {
                    try {
                      await quranProvider.loadSurahs();
                      ToastService.showSuccess('Data refreshed');
                    } catch (e) {
                      ToastService.showError('Failed to refresh data');
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Refresh',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FontAwesomeIcons.bookQuran,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'القرآن الكريم',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'The Holy Quran',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Settings button
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: const Icon(
                  Icons.settings,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primary,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.list, size: 20),
                text: 'All Surahs',
              ),
              Tab(
                icon: Icon(Icons.bookmark, size: 20),
                text: 'Bookmarked',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSurahList(QuranDataProvider quranProvider) {
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: false,
      header: const WaterDropHeader(),
      onRefresh: () async {
        try {
          await quranProvider.loadSurahs();
          if (quranProvider.isOfflineMode) {
            ToastService.showOfflineMode();
          } else {
            ToastService.showSuccess('Data refreshed successfully');
          }
        } catch (e) {
          ToastService.showError('Failed to refresh data');
        } finally {
          _refreshController.refreshCompleted();
        }
      },
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: quranProvider.surahs.length,
          itemBuilder: (context, index) {
            final surah = quranProvider.surahs[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: SurahCard(
                    surah: surah,
                    onTap: () => context.push('/surah/${surah.number}'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }



}
