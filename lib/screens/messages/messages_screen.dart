import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messageService = MessageService();
    final currentUserId = 'TODO'; // Get from auth service

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<MessageModel>>(
        stream: messageService.getMessages(currentUserId, ''),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data ?? [];

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ListTile(
                leading: const CircleAvatar(),
                title: Text(message.senderId), // TODO: Get user name
                subtitle: Text(message.content),
                trailing: !message.isRead ? const CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.blue,
                ) : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(otherUserId: message.senderId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
