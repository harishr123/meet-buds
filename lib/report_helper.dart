import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> showReportDialog(
  BuildContext context, {
  required String postId,
  required String reportedUserId,
}) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (context) {
      String selected = 'Inappropriate content';
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Inappropriate content', 'Spam', 'Harassment', 'Other']
                .map(
                  (r) => RadioListTile<String>(
                    title: Text(r),
                    value: r,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v!),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Report'),
            ),
          ],
        ),
      );
    },
  );

  if (reason == null || !context.mounted) return;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  try {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc('${postId}_$uid')
        .set({
          'postId': postId,
          'reportedUserId': reportedUserId,
          'reporterId': uid,
          'reason': reason,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post reported. Thanks for flagging this.')),
    );
  } on FirebaseException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.code == 'permission-denied'
              ? 'You have already reported this post.'
              : 'Could not submit report. Please try again.',
        ),
      ),
    );
  }
}
