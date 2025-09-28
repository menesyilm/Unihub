import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  String buildRoomId({required String university, required String activity}) {
    return '${_normalize(university)}_${_normalize(activity)}';
  }

  Future<String> getOrCreateRoom({
    required String university,
    required String activity,
  }) async {
    final roomId = buildRoomId(university: university, activity: activity);
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    final doc = await roomRef.get();

    if (!doc.exists) {
      await roomRef.set({
        'university': university,
        'activity': activity,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }

    // ensure participant exists
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await roomRef.collection('participants').doc(uid).set({
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return roomId;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final uid = _auth.currentUser?.uid;
    final email = _auth.currentUser?.email;
    if (uid == null || text.trim().isEmpty) return;

    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    final msgRef = roomRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': uid,
      'senderEmail': email,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await roomRef.set({
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
