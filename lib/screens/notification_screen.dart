import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() {
    return _NotificationScreenState();
  }
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, String>> notifications = [
    {
      'title': 'Vista rewards club...',
      'date': 'Dec 16, 2025',
      'description':
          'Earn Points without making a purchase. Complete your first mission today!',
    },
    {
      'title': 'The Vista rewards...',
      'date': 'Dec 12, 2025',
      'description':
          'Keep paying with Vista to boost your points and unlock rewards. It’s as simple as that.',
    },
    {
      'title': 'The Vista rewards...',
      'date': 'Dec 8, 2025',
      'description':
          'Now you’re a member of Vista rewards club, start picking up points with every purchase.',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Customize',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),

      body: notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];

        return Card(
          elevation: 0.02,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.pink.shade100,
              child: Text('V', style: TextStyle(color: Colors.pink)),
            ),
            title: Text(
              notification['title'] ?? '',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['description'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.pink),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              "No Notifications yet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your Notification will appear here once you've received them.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
