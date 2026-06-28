import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../post_model.dart';
import '../post_service.dart';
import '../post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _postService = PostService();
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  bool _loadingProfile = true;
  bool _editingBio = false;
  final _bioController = TextEditingController();

  bool get _isOwnProfile =>
      FirebaseAuth.instance.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _postService.getUserProfile(widget.userId);
    setState(() {
      _profile = data;
      _bioController.text = data?['bio'] ?? '';
      _loadingProfile = false;
    });
  }

  Future<void> _saveBio() async {
    await _postService.updateBio(_bioController.text.trim());
    setState(() {
      _profile?['bio'] = _bioController.text.trim();
      _editingBio = false;
    });
  }

  Color _avatarColor(String username) {
    final colors = [
      const Color(0xFFEEEDFE),
      const Color(0xFFE1F5EE),
      const Color(0xFFFAECE7),
      const Color(0xFFE6F1FB),
      const Color(0xFFFBEAF0),
    ];
    return colors[username.codeUnitAt(0) % colors.length];
  }

  Color _avatarTextColor(String username) {
    final colors = [
      const Color(0xFF3C3489),
      const Color(0xFF085041),
      const Color(0xFF993C1D),
      const Color(0xFF0C447C),
      const Color(0xFF72243E),
    ];
    return colors[username.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final username = _profile?['username'] ?? 'User';
    final bio = _profile?['bio'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(username,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _avatarColor(username),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            username[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: _avatarTextColor(username),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(username,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),

                      // Bio
                      if (_isOwnProfile && _editingBio)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _bioController,
                                maxLines: 2,
                                maxLength: 100,
                                decoration: const InputDecoration(
                                  hintText: 'Write something about yourself...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: Color(0xFF1D9E75)),
                              onPressed: _saveBio,
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: _isOwnProfile
                              ? () => setState(() => _editingBio = true)
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                bio.isEmpty
                                    ? (_isOwnProfile
                                        ? 'Tap to add a bio...'
                                        : '')
                                    : bio,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: bio.isEmpty
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_isOwnProfile) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.edit,
                                    size: 13, color: Colors.grey.shade400),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF3C3489),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF3C3489),
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Joined'),
                  ],
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Posts tab
                      StreamBuilder<List<PostModel>>(
                        stream: _postService.getPostsByUser(widget.userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final posts = snapshot.data ?? [];
                          if (posts.isEmpty) {
                            return Center(
                              child: Text('No posts yet',
                                  style: TextStyle(
                                      color: Colors.grey.shade400)),
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

                      // Joined tab
                      StreamBuilder<List<PostModel>>(
                        stream:
                            _postService.getJoinedActivities(widget.userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final posts = snapshot.data ?? [];
                          if (posts.isEmpty) {
                            return Center(
                              child: Text('No joined activities yet',
                                  style: TextStyle(
                                      color: Colors.grey.shade400)),
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
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}