import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


const String _kPostsCollection = 'posts';
const String _kPostAuthorField = 'userId';
const String _kPostTitleField = 'username';
const String _kPostBodyField = 'text';

const String _kUsersCollection = 'users';
const String _kReportsCollection = 'reports';


Future<bool> isCurrentUserModerator() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;
  try {
    final doc = await FirebaseFirestore.instance
        .collection(_kUsersCollection)
        .doc(uid)
        .get();
    return doc.data()?['isModerator'] == true;
  } catch (_) {
    return false;
  }
}


class _ReportGroup {
  _ReportGroup(this.postId);

  final String postId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> reports = [];

  int get count => reports.length;


  DateTime get latest {
    DateTime newest = DateTime.fromMillisecondsSinceEpoch(0);
    for (final r in reports) {
      final ts = r.data()['timestamp'];
      if (ts is Timestamp && ts.toDate().isAfter(newest)) newest = ts.toDate();
    }
    return newest;
  }


  Map<String, int> get reasonTally {
    final tally = <String, int>{};
    for (final r in reports) {
      final reason = (r.data()['reason'] as String?) ?? 'Other';
      tally[reason] = (tally[reason] ?? 0) + 1;
    }
    return tally;
  }
}

class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection(_kReportsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderation')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _CentredMessage(
              icon: Icons.error_outline,
              title: 'Could not load reports',
              subtitle: '${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = _group(snapshot.data!.docs);
          if (groups.isEmpty) {
            return const _CentredMessage(
              icon: Icons.check_circle_outline,
              title: 'Nothing to review',
              subtitle: 'No pending reports.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ReportCard(group: groups[i]),
          );
        },
      ),
    );
  }


  List<_ReportGroup> _group(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final byPost = <String, _ReportGroup>{};
    for (final doc in docs) {
      final postId = doc.data()['postId'] as String?;
      if (postId == null) continue;
      byPost.putIfAbsent(postId, () => _ReportGroup(postId)).reports.add(doc);
    }
    final groups = byPost.values.toList();
    groups.sort((a, b) => b.latest.compareTo(a.latest));
    return groups;
  }
}

class _ReportCard extends StatefulWidget {
  const _ReportCard({required this.group});

  final _ReportGroup group;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(count: group.count, tally: group.reasonTally),
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection(_kPostsCollection)
                .doc(group.postId)
                .get(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // The post may already be gone — deleted by its author, or by
              // another moderator. Show a tombstone rather than throwing.
              final exists = snap.hasData && (snap.data?.exists ?? false);
              final data = exists ? snap.data!.data() : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data == null)
                    const _Tombstone()
                  else
                    _PostPreview(data: data),
                  const Divider(height: 1),
                  _Actions(
                    busy: _busy,
                    postExists: data != null,
                    onDismiss: () => _run(() => _dismiss(group)),
                    onDelete: () => _run(() => _deletePost(group)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  Future<void> _dismiss(_ReportGroup group) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();
    for (final report in group.reports) {
      batch.update(report.reference, {
        'status': 'resolved',
        'resolution': 'dismissed',
        'resolvedBy': uid,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    _toast('Dismissed ${group.count} report(s)');
  }

  Future<void> _deletePost(_ReportGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text(
          'The post will be removed for everyone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(
      FirebaseFirestore.instance
          .collection(_kPostsCollection)
          .doc(group.postId),
    );
    for (final report in group.reports) {
      batch.update(report.reference, {
        'status': 'resolved',
        'resolution': 'post_deleted',
        'resolvedBy': uid,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    _toast('Post deleted');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.tally});

  final int count;
  final Map<String, int> tally;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Text(
            count == 1 ? '1 report' : '$count reports',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tally.entries.map((e) => '${e.key} (${e.value})').join(' · '),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onErrorContainer.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = (data[_kPostTitleField] as String?)?.trim();
    final body = (data[_kPostBodyField] as String?)?.trim();
    final author = data[_kPostAuthorField] as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty)
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body, maxLines: 4, overflow: TextOverflow.ellipsis),
          ],
          if (author != null) ...[
            const SizedBox(height: 10),
            Text(
              'Author: $author',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Tombstone extends StatelessWidget {
  const _Tombstone();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.delete_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This post no longer exists. Dismiss to clear the reports.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.busy,
    required this.postExists,
    required this.onDismiss,
    required this.onDelete,
  });

  final bool busy;
  final bool postExists;
  final VoidCallback onDismiss;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
          const SizedBox(width: 4),
          if (postExists)
            TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete post'),
            ),
        ],
      ),
    );
  }
}

class _CentredMessage extends StatelessWidget {
  const _CentredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
