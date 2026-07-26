const {onDocumentUpdated, onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Sends a push notification to a single user, if they have a saved
 * FCM token. Silently does nothing if the token is missing (e.g. the
 * user has never opened the app, or notifications were cleared on logout).
 */
async function sendToUser(uid, title, body, data = {}) {
  const userDoc = await db.collection("users").doc(uid).get();
  const token = userDoc.data() && userDoc.data().fcmToken;
  if (!token) return;

  try {
    await messaging.send({
      token,
      notification: {title, body},
      data,
    });
  } catch (err) {
    console.error(`Failed to send notification to ${uid}:`, err);
  }
}

/**
 * Fires whenever a post document is updated. Compares the joinedBy
 * array before/after to find newly-added joiners, and notifies the
 * post owner about each one (skipping the case where the owner joins
 * their own post).
 */
exports.notifyOnJoin = onDocumentUpdated("posts/{postId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const postId = event.params.postId;

  const beforeJoined = before.joinedBy || [];
  const afterJoined = after.joinedBy || [];

  // Only care about people who are newly present in joinedBy.
  const newJoiners = afterJoined.filter((uid) => !beforeJoined.includes(uid));
  if (newJoiners.length === 0) return;

  const ownerId = after.userId;

  for (const joinerId of newJoiners) {
    if (joinerId === ownerId) continue;

    const joinerDoc = await db.collection("users").doc(joinerId).get();
    const joinerName = (joinerDoc.data() && joinerDoc.data().username) || "Someone";

    await sendToUser(
        ownerId,
        "New join!",
        `${joinerName} joined your activity`,
        {type: "join", postId},
    );
  }
});

/**
 * Fires whenever a new comment is created under a post. Notifies the
 * post owner, unless they are commenting on their own post.
 */
exports.notifyOnComment = onDocumentCreated(
    "posts/{postId}/comments/{commentId}",
    async (event) => {
      const comment = event.data.data();
      const postId = event.params.postId;

      const postDoc = await db.collection("posts").doc(postId).get();
      if (!postDoc.exists) return;
      const post = postDoc.data();
      const ownerId = post.userId;

      if (comment.userId === ownerId) return;

      const preview = comment.text.length > 80 ?
        `${comment.text.slice(0, 80)}...` :
        comment.text;

      await sendToUser(
          ownerId,
          comment.replyToId ? "New reply!" : "New comment!",
          `${comment.username}: ${preview}`,
          {type: "comment", postId},
      );
    },
);