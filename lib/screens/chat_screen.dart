import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:chat_app/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedinUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  
  final _auth = FirebaseAuth.instance;

  String? messegetext;
  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedinUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessegesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messegetext = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (messegetext != null &&
                          messegetext!.isNotEmpty &&
                          loggedinUser != null) {
                        messageTextController.clear();
                        _firestore.collection('messages').add({
                          'text': messegetext,
                          'sender': loggedinUser!.email,
                          'timestamp': FieldValue
                              .serverTimestamp(), // Add a timestamp for sorting
                        });
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),

                  // TextButton(
                  //   onPressed: () {
                  //     messageTextController.clear();
                  //     _firestore.collection('messeges').add({
                  //       'text': messegetext,
                  //       'sender': loggedinUser!.email,
                  //     });
                  //   },
                  //   child: Text(
                  //     'Send',
                  //     style: kSendButtonTextStyle,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessegesStream extends StatelessWidget {
  const MessegesStream({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('timestamp').snapshots(),
      builder: (context, snapshot) {
        List<MessageBubble> messageBubbles = [];
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messeges = snapshot.data!.docs.reversed;
        for (var message in messeges) {
          final messegeText = message.get('text');
          final messegeSender = message.get('sender');
          final currentUser = loggedinUser!.email;
          final messegeBubble = MessageBubble(
            text: messegeText,
            sender: messegeSender,
            isMe: currentUser == messegeSender,
          );
          messageBubbles.add(messegeBubble);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe});
  final String? sender;
  final String? text;
  final bool? isMe;

  String _getDisplayText() {
    if (isMe!) {
      return text!;
    } else {
      return '$text'; // Display sender's email with the message for messages from other users
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe!) // Display sender's email only for messages from other users
            Text(
              sender!,
              style: TextStyle(fontSize: 12.0, color: Colors.black54),
            ),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: isMe! ? Radius.circular(30.0) : Radius.zero,
              topRight: isMe! ? Radius.zero : Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ),
            elevation: 5.0,
            color: isMe! ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 20.0,
              ),
              child: Text(
                _getDisplayText(), // Use the modified display text
                style: TextStyle(
                  fontSize: 15.0,
                  color: isMe! ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class MessageBubble extends StatelessWidget {
//   MessageBubble({this.sender, this.text, this.isMe});
//   final String? sender;
//   final String? text;
//   final bool? isMe;
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.all(10.0),
//       child: Column(
//         crossAxisAlignment:
//             isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Text(
//             sender!,
//             style: TextStyle(fontSize: 12.0, color: Colors.black54),
//           ),
//           Material(
//             borderRadius: isMe!
//                 ? BorderRadius.only(
//                     topLeft: Radius.circular(30.0),
//                     bottomLeft: Radius.circular(30.0),
//                     bottomRight: Radius.circular(30.0),
//                   )
//                 : BorderRadius.only(
//                     topRight: Radius.circular(30.0),
//                     bottomLeft: Radius.circular(30.0),
//                     bottomRight: Radius.circular(30.0),
//                   ),
//             elevation: 5.0,
//             color: isMe! ? Colors.lightBlueAccent : Colors.white,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(
//                 vertical: 10.0,
//                 horizontal: 20.0,
//               ),
//               child: Text(
//                 isMe! ? '$text' : '$text from $sender',
//                 style: TextStyle(
//                   fontSize: 50.0,
//                   color: isMe! ? Colors.white : Colors.black54,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
