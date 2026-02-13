// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class FirebaseMessagingService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   Future<void> initialize() async {
//     // Request permission for iOS devices
//     await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     // Initialize local notifications
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const DarwinInitializationSettings initializationSettingsIOS =
//         DarwinInitializationSettings();
//     const InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );

//     await _flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         // Handle notification tap
//         print('Notification tapped: ${response.payload}');
//       },
//     );

//     // Get FCM token
//     // String? token = await _firebaseMessaging.getToken();
//     // print('FCM Token: $token');

//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _showNotification(message);
//     });

//     // Handle background messages
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//     // Handle when app is opened from notification
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('Message opened app: ${message.data}');
//     });
//   }

//   Future<void> _showNotification(RemoteMessage message) async {
//     RemoteNotification? notification = message.notification;
//     AndroidNotification? android = message.notification?.android;

//     if (notification != null && android != null) {
//       await _flutterLocalNotificationsPlugin.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'high_importance_channel',
//             'High Importance Notifications',
//             channelDescription:
//                 'This channel is used for important notifications',
//             importance: Importance.max,
//             priority: Priority.high,
//           ),
//           iOS: const DarwinNotificationDetails(),
//         ),
//         payload: message.data.toString(),
//       );
//     }
//   }
// }

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print('Handling a background message: ${message.messageId}');
// }
