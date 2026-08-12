import 'package:flutter/material.dart';
import 'post_service.dart';
import 'post_card.dart';
import 'post_model.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _postService = PostService();
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const _filters = [
    {'type': 'all', 'label': 'All', 'emoji': ''},
    {'type': 'gym', 'label': 'Gym', 'emoji': '🏋️'},
    {'type': 'food', 'label': 'Food', 'emoji': '🍜'},
    {'type': 'study', 'label': 'Study', 'emoji': '📚'},
    {'type': 'sports', 'label': 'Sports', 'emoji': '⚽'},
    {'type': 'hangout', 'label': 'Hangout', 'emoji': '☕'},
    {'type': 'general', 'label': 'Other', 'emoji': '📌'},
  ];

  static const _filterColors = {
    'all': Color(0xFF3C3489),
    'gym': Color(0xFF085041),
    'food': Color(0xFF993C1D),
    'study': Color(0xFF0C447C),
    'sports': Color(0xFF3B6D11),
    'hangout': Color(0xFF854F0B),
    'general': Color(0xFF534AB7),
  };

  static const _filterBgColors = {
    'all': Color(0xFFEEEDFE),
    'gym': Color(0xFFE1F5EE),
    'food': Color(0xFFFAECE7),
    'study': Color(0xFFE6F1FB),
    'sports': Color(0xFFEAF3DE),
    'hangout': Color(0xFFFAEEDA),
    'general': Color(0xFFEEEDFE),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Feed'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search activities or locations...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final selected = _selectedFilter == f['type'];
                final color =
                    _filterColors[f['type']] ?? const Color(0xFF3C3489);
                final bgColor =
                    _filterBgColors[f['type']] ?? const Color(0xFFEEEDFE);
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f['type']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? bgColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (f['emoji']!.isNotEmpty) ...[
                          Text(
                            f['emoji']!,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          f['label']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selected ? color : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Feed
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: _postService.getFeed(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dynamic_feed_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No posts yet. Be the first!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Apply filters
                var posts = snapshot.data!;
                if (_selectedFilter != 'all') {
                  posts = posts
                      .where((p) => p.activityType == _selectedFilter)
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  posts = posts.where((p) {
                    return p.text.toLowerCase().contains(_searchQuery) ||
                        (p.location?.toLowerCase().contains(_searchQuery) ??
                            false) ||
                        p.username.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery"'
                              : 'No $_selectedFilter activities yet',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (_, i) => PostCard(
                    key: ValueKey(posts[i].id),
                    post: posts[i],
                    postService: _postService,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
