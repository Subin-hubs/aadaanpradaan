import 'dart:convert';
import 'package:aadanpradaan/pages/1s_Page/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '2nd_Page.dart';

class MessengerChatListPage extends StatefulWidget {
  const MessengerChatListPage({Key? key}) : super(key: key);

  @override
  State<MessengerChatListPage> createState() => _MessengerChatListPageState();
}

class _MessengerChatListPageState extends State<MessengerChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _updateUserOnlineStatus(true);
  }

  @override
  void dispose() {
    _updateUserOnlineStatus(false);
    super.dispose();
  }

  Future<void> _updateUserOnlineStatus(bool isOnline) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating online status: $e');
      }
    }
  }

  String formatLastMessageTime(Timestamp timestamp) {
    DateTime messageTime = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return DateFormat('h:mm a').format(messageTime);
    } else if (messageDate.isAfter(today.subtract(Duration(days: 7)))) {
      return DateFormat('EEE').format(messageTime); // Mon, Tue, etc.
    } else {
      return DateFormat('MMM d').format(messageTime); // Jan 1, etc.
    }
  }

  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return {};
  }

  String createChatId(String userId1, String userId2) {
    List<String> participants = [userId1, userId2];
    participants.sort();
    return participants.join('_');
  }

  Future<void> _startNewChat() async {
    // Show dialog to select user to chat with
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Start New Chat', style: TextStyle(color: Colors.black)),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: Colors.blue));
              }

              final users = snapshot.data!.docs.where((doc) {
                return doc.id != _auth.currentUser!.uid;
              }).toList();

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  final userName = '${userData['fname'] ?? ''} ${userData['lname'] ?? ''}'.trim();
                  final profilePic = userData['ppimage'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profilePic.isNotEmpty
                          ? MemoryImage(base64Decode(profilePic))
                          : AssetImage('assets/defaultimg.png') as ImageProvider,
                    ),
                    title: Text(userName.isNotEmpty ? userName : 'Unknown User',
                        style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverUserID: users[index].id,
                            receiverUserName: userName,
                            receiverName: userName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Text('Please log in to view chats',
                style: TextStyle(color: Colors.black))
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Chats',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.black),
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('participants', arrayContains: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Colors.blue));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message, color: Colors.grey[600], size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No chats yet',
                          style: TextStyle(color: Colors.grey[600], fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a new conversation',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _startNewChat,
                          child: Text('Start New Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final chats = snapshot.data!.docs;

                // Sort chats by lastMessageTime in code
                chats.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['lastMessageTime'] as Timestamp?;
                  final bTime = bData['lastMessageTime'] as Timestamp?;

                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;

                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chatData = chats[index].data() as Map<String, dynamic>;
                    final participants = List<String>.from(chatData['participants'] ?? []);
                    final lastMessage = chatData['lastMessage'] ?? '';
                    final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
                    final lastMessageSender = chatData['lastMessageSender'] ?? '';

                    // Get the other participant (not current user)
                    final otherParticipantId = participants.firstWhere(
                          (id) => id != currentUser.uid,
                      orElse: () => '',
                    );

                    if (otherParticipantId.isEmpty) {
                      return SizedBox.shrink();
                    }

                    return FutureBuilder<Map<String, dynamic>>(
                      future: getUserData(otherParticipantId),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[300],
                              child: Icon(Icons.person, color: Colors.black),
                            ),
                            title: Text(
                              'Loading...',
                              style: TextStyle(color: Colors.black),
                            ),
                            subtitle: Text(
                              'Please wait...',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          );
                        }

                        final userData = userSnapshot.data!;
                        final userName = '${userData['fname'] ?? ''} ${userData['lname'] ?? ''}'.trim();
                        final profilePic = userData['ppimage'] ?? '';
                        final isOnline = userData['isOnline'] ?? false;

                        // Count unread messages
                        return StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('chats')
                              .doc(createChatId(currentUser.uid, otherParticipantId))
                              .collection('messages')
                              .where('receiverId', isEqualTo: currentUser.uid)
                              .where('isRead', isEqualTo: false)
                              .snapshots(),
                          builder: (context, unreadSnapshot) {
                            int unreadCount = unreadSnapshot.hasData ? unreadSnapshot.data!.docs.length : 0;

                            return ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: profilePic.isNotEmpty
                                        ? MemoryImage(base64Decode(profilePic))
                                        : AssetImage('assets/defaultimg.png') as ImageProvider,
                                  ),
                                  if (isOnline)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                userName.isNotEmpty ? userName : 'Unknown User',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  if (lastMessageSender == currentUser.uid)
                                    Text(
                                      'You: ',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                                      style: TextStyle(
                                        color: unreadCount > 0 ? Colors.black : Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (lastMessageTime != null) ...[
                                    Text(' • ', style: TextStyle(color: Colors.grey[600])),
                                    Text(
                                      formatLastMessageTime(lastMessageTime),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: unreadCount > 0
                                  ? Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                                  : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      receiverUserID: otherParticipantId,
                                      receiverUserName: userName,
                                      receiverName: userName,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}