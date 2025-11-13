import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// HANDLE BACKGROUND MESSAGES
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔵 Background Message: ${message.notification?.body}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MessagingApp());
}

class MessagingApp extends StatelessWidget {
  const MessagingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Demo',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? fcmToken = "";
  String? lastMessage = "Waiting for notifications...";

  @override
  void initState() {
    super.initState();
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // GET TOKEN
    messaging.getToken().then((token) {
      print("🔑 FCM Token: $token");
      setState(() => fcmToken = token);
    });

    // FOREGROUND MESSAGES
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Message Received!");
      print(message.notification?.title);
      print(message.notification?.body);
      print(message.data);

      // Determine notification type
      String type = message.data["type"] ?? "regular";

      if (type == "important") {
        _showImportantNotification(message);
      } else {
        _showNotificationDialog(message);
      }

      setState(() => lastMessage =
          "Title: ${message.notification?.title}\nBody: ${message.notification?.body}");
    });

    // WHEN TAPPED FROM BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📨 Message opened!");
    });
  }

  void _showNotificationDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message.notification?.title ?? "Notification"),
        content: Text(message.notification?.body ?? ""),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _showImportantNotification(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade100,
        title: Text(
          "[IMPORTANT] ${message.notification?.title}",
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          message.notification?.body ?? "",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase Cloud Messaging")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Your FCM Token:"),
            SelectableText(fcmToken ?? "", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            const Text("Latest Notification:"),
            const SizedBox(height: 10),
            Text(lastMessage ?? ""),
          ],
        ),
      ),
    );
  }
}