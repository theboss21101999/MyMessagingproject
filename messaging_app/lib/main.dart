import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'local_database.dart';
import 'contact_service.dart';
import 'firestore_service.dart';
import 'notification_service.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messaging App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AuthService _authService = AuthService();
  final LocalDatabase _localDatabase = LocalDatabase.instance;
  final ContactService _contactService = ContactService();
  final FirestoreService _firestoreService = FirestoreService();
  
  User? _currentUser;
  String _receiverPhoneNumber = '';
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    _authService.signInWithPhone('+1234567890', (PhoneAuthCredential credential) async {
      await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() {
        _currentUser = FirebaseAuth.instance.currentUser;
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_receiverPhoneNumber.isEmpty || _messageController.text.isEmpty) {
      return;
    }

    bool hasContact = await _contactService.hasContact(_receiverPhoneNumber);
    if (!hasContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receiver not in contacts')),
      );
      return;
    }

    await _firestoreService.sendMessage(
      _currentUser!.phoneNumber!,
      _receiverPhoneNumber,
      _messageController.text,
    );

    await _localDatabase.createMessage({
      'sender': _currentUser!.phoneNumber!,
      'receiver': _receiverPhoneNumber,
      'content': _messageController.text,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Messaging App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Enter receiver phone number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                _receiverPhoneNumber = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Enter your message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Send Message'),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.getMessages(_currentUser?.phoneNumber ?? ''),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Map<String, dynamic>> messages = snapshot.data!;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      return ListTile(
                        title: Text(message['content']),
                        subtitle: Text(message['sender']),
                        trailing: IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () async {
                            await _firestoreService.markAsRead(message['id']);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
