import 'package:anime_verse/widgets/anime_view.dart';
import 'package:anime_verse/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/app_state_provider.dart';
import '../widgets/genre_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      if (provider.selectedGenre == "All") {
        provider.loadMoreAnime();
      }
    }
  }

  Widget _buildContentArea(AppStateProvider provider, double screenHeight) {
    if (provider.isLoading) {
      return SizedBox(
        height: screenHeight * 0.4,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading anime...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return SizedBox(
        height: screenHeight * 0.4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${provider.errorMessage}',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  provider.fetchTopAnime();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredAnime = provider.getFilteredAnimeForHome();

    if (filteredAnime.isEmpty) {
      return SizedBox(
        height: screenHeight * 0.4,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.white38,
              ),
              SizedBox(height: 16),
              Text(
                'No anime found',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search',
                style: TextStyle(color: Colors.white38),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return AnimeView(animeList: filteredAnime);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          "AnimeVerse",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: screenWidth * 0.075,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchTopAnime();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Search Bar
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(screenWidth * 0.075),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: screenWidth * 0.02,
                            offset: Offset(0, screenHeight * 0.005),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          provider.setHomeSearchQuery(value);
                        },
                        decoration: InputDecoration(
                          hintText: "Anime Title",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: screenWidth * 0.04,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: screenWidth * 0.06,
                          ),
                          suffixIcon: provider.homeSearchQuery.isNotEmpty
                              ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: screenWidth * 0.06,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              provider.setHomeSearchQuery('');
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.075),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.075),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.075),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          filled: true,
                          fillColor: Color(0xFF0b395e),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.015,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Genre List
                  GenreList(
                    selected: provider.selectedGenre,
                    onGenreSelected: (genre) {
                      provider.setSelectedGenre(genre);
                    },
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  _buildContentArea(provider, screenHeight),

                  if (provider.isLoadingMore)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      child: const Column(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 8),
                          Text(
                            'Loading more anime...',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  if (!provider.hasMore &&
                      !provider.isSearchMode &&
                      provider.selectedGenre == "All" &&
                      provider.animeList.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      child: const Text(
                        '🎬 You\'ve reached the end!',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ),

                  if (provider.selectedGenre != "All" &&
                      provider.animeList.isNotEmpty &&
                      !provider.isLoading)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      child: Text(
                        'Showing ${provider.getFilteredAnimeForHome().length} ${provider.selectedGenre} anime from ${provider.animeList.length} loaded',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(height: screenHeight * 0.025),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}