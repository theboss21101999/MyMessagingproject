import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendMessage(String sender, String receiver, String content) async {
    await _db.collection('messages').add({
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Stream<List<Map<String, dynamic>>> getMessages(String user) {
    return _db.collection('messages')
        .where('receiver', isEqualTo: user)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> markAsRead(String docId) async {
    await _db.collection('messages').doc(docId).update({'read': true});
  }
}
