import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserID;
  final String receiverUserName;
  final String receiverName;

  const ChatPage({
    Key? key,
    required this.receiverUserID,
    required this.receiverUserName,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  String? _chatId;
  Map<String, dynamic> _receiverData = {};
  bool _isLoading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _loadReceiverData();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  void _initializeChat() {
    final currentUserId = _auth.currentUser!.uid;
    final receiverId = widget.receiverUserID;

    // Create consistent chat ID regardless of who starts the chat
    List<String> participants = [currentUserId, receiverId];
    participants.sort(); // Sort to ensure consistent chat ID
    _chatId = participants.join('_');
  }

  Future<void> _loadReceiverData() async {
    try {
      DocumentSnapshot receiverDoc = await _firestore
          .collection('users')
          .doc(widget.receiverUserID)
          .get();

      if (receiverDoc.exists) {
        setState(() {
          _receiverData = receiverDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading receiver data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_chatId == null) return;

    try {
      // Get all unread messages for current user
      QuerySnapshot unreadMessages = await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: _auth.currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark all as read
      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _auth.currentUser!;
    final messageText = _messageController.text.trim();
    final timestamp = Timestamp.now();

    // Clear message input immediately for better UX
    _messageController.clear();

    try {
      // Get current user data for message
      DocumentSnapshot currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      Map<String, dynamic> currentUserData = {};
      if (currentUserDoc.exists) {
        currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      }

      // Add message to messages subcollection
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': '${currentUserData['fname'] ?? ''} ${currentUserData['lname'] ?? ''}'.trim(),
        'receiverId': widget.receiverUserID,
        'message': messageText,
        'timestamp': timestamp,
        'isRead': false,
        'messageType': 'text', // For future expansion (image, video, etc.)
      });

      // Update or create chat document with last message info
      await _firestore.collection('chats').doc(_chatId).set({
        'participants': [currentUser.uid, widget.receiverUserID],
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSender': currentUser.uid,
        'chatId': _chatId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
      // Restore message text on error
      _messageController.text = messageText;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(Timestamp timestamp) {
    DateTime messageTime = timestamp.toDate();
    DateTime now = DateTime.now();

    if (DateUtils.isSameDay(messageTime, now)) {
      return DateFormat('h:mm a').format(messageTime);
    } else if (now.difference(messageTime).inDays < 7) {
      return DateFormat('EEE h:mm a').format(messageTime);
    } else {
      return DateFormat('MMM d, h:mm a').format(messageTime);
    }
  }

  String _getLastSeenText() {
    if (_receiverData['isOnline'] == true) {
      return 'Active now';
    }

    if (_receiverData['lastSeen'] != null) {
      Timestamp lastSeen = _receiverData['lastSeen'];
      DateTime lastSeenTime = lastSeen.toDate();
      DateTime now = DateTime.now();

      Duration difference = now.difference(lastSeenTime);

      if (difference.inMinutes < 1) {
        return 'Active now';
      } else if (difference.inMinutes < 60) {
        return 'Active ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Active ${difference.inHours}h ago';
      } else {
        return 'Active ${DateFormat('MMM d').format(lastSeenTime)}';
      }
    }

    return '';
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe, bool showTime) {
    final message = messageData['message'] ?? '';
    final timestamp = messageData['timestamp'] as Timestamp?;
    final isRead = messageData['isRead'] ?? false;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            if (showTime && timestamp != null)
              Padding(
                padding: EdgeInsets.only(top: 4, left: 8, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 16,
                        color: isRead ? Colors.blue : Colors.grey[600],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DateFormat('MMM d, y').format(date),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: _receiverData['ppimage'] != null && _receiverData['ppimage'].isNotEmpty
                ? MemoryImage(base64Decode(_receiverData['ppimage']))
                : AssetImage('assets/defaultimg.png') as ImageProvider,
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: 4),
                _buildTypingDot(1),
                SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.receiverName,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profilePic = _receiverData['ppimage'] ?? '';
    final isOnline = _receiverData['isOnline'] ?? false;
    final lastSeenText = _getLastSeenText();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: profilePic.isNotEmpty
                      ? MemoryImage(base64Decode(profilePic))
                      : AssetImage('assets/defaultimg.png') as ImageProvider,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (lastSeenText.isNotEmpty)
                    Text(
                      lastSeenText,
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.video_call, color: Colors.blue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Video call feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.call, color: Colors.blue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Voice call feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.blue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chat info feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _chatId != null
                ? StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: profilePic.isNotEmpty
                              ? MemoryImage(base64Decode(profilePic))
                              : AssetImage('assets/defaultimg.png') as ImageProvider,
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.receiverName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Say hello or share something to get the conversation started!',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                final currentUserId = _auth.currentUser!.uid;

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator at the end
                    if (_isTyping && index == messages.length) {
                      return _buildTypingIndicator();
                    }

                    final messageDoc = messages[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;
                    final senderId = messageData['senderId'] ?? '';
                    final isMe = senderId == currentUserId;
                    final timestamp = messageData['timestamp'] as Timestamp?;

                    // Check if we should show time (show for last message or if significant time gap)
                    bool showTime = false;
                    if (index == messages.length - 1) {
                      showTime = true;
                    } else if (index < messages.length - 1) {
                      final nextMessageData = messages[index + 1].data() as Map<String, dynamic>;
                      final nextTimestamp = nextMessageData['timestamp'] as Timestamp?;
                      if (timestamp != null && nextTimestamp != null) {
                        final timeDiff = nextTimestamp.toDate().difference(timestamp.toDate());
                        showTime = timeDiff.inMinutes > 5;
                      }
                    }

                    // Check if we should show date separator
                    Widget? dateSeparator;
                    if (index == 0) {
                      if (timestamp != null) {
                        dateSeparator = _buildDateSeparator(timestamp.toDate());
                      }
                    } else {
                      final prevMessageData = messages[index - 1].data() as Map<String, dynamic>;
                      final prevTimestamp = prevMessageData['timestamp'] as Timestamp?;
                      if (timestamp != null && prevTimestamp != null) {
                        final currentDate = timestamp.toDate();
                        final prevDate = prevTimestamp.toDate();
                        if (!DateUtils.isSameDay(currentDate, prevDate)) {
                          dateSeparator = _buildDateSeparator(currentDate);
                        }
                      }
                    }

                    return Column(
                      children: [
                        if (dateSeparator != null) dateSeparator,
                        _buildMessageBubble(messageData, isMe, showTime),
                      ],
                    );
                  },
                );
              },
            )
                : Center(child: Text('Error loading chat')),
          ),

          // Message input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.blue),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('File attachment feature coming soon!')),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey[600]),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (text) {
                          // You can implement typing indicators here
                          // For now, we'll keep it simple
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _messageController.text.trim().isNotEmpty ? Colors.blue : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}