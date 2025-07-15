import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';

void showCommentsModal(
  BuildContext context,
  String confessionId, {
  VoidCallback? onNewComment,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: CommentsModalContent(
          confessionId: confessionId,
          onNewComment: onNewComment,
        ),
      );
    },
  );
}

class CommentsModalContent extends StatefulWidget {
  final String confessionId;
  final VoidCallback? onNewComment;

  const CommentsModalContent({
    super.key,
    required this.confessionId,
    this.onNewComment,
  });

  @override
  State<CommentsModalContent> createState() => _CommentsModalContentState();
}

class _CommentsModalContentState extends State<CommentsModalContent> {
  late IO.Socket socket;

  bool isLoading = true;
  bool isPosting = false;
  List<Map<String, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();

  String username = 'Anonymous';
  String userId = '';
  String? quotedCommentId;
  String? quotedUsername;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchComments();
    initSocket();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Anonymous';
      userId = prefs.getString('userId') ?? '';
    });
  }

  void initSocket() {
    socket = IO.io('https://whisper-2nhg.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connected to socket server ${widget.confessionId}');

      socket.emit('joinConfession', {'confessionId': widget.confessionId});
    });

    socket.on('commentAdded', (data) {
      print('Comment Added by USER--------- $data');
      if (!mounted) return;
      setState(() {
        if (data is Map) {
          String newId = data['_id'];
          bool alreadyExists = comments.any((c) => c['_id'] == newId);
          if (!alreadyExists) {
            Map<String, dynamic> newComment = Map<String, dynamic>.from(data);

            // ✅ If it's a top-level comment (not a reply), insert at top
            if (newComment['quotedCommentId'] == null ||
                (newComment['quotedCommentId'] is String &&
                    newComment['quotedCommentId'].toString().isEmpty)) {
              comments.insert(0, newComment);
            } else {
              comments.add(
                newComment,
              ); // Let replies be handled via comment tree
            }
          }
        }
        isLoading = false;
      });
    });

    socket.onDisconnect((_) => print('❌ Disconnected from socket server'));
  }

  Future<void> fetchComments() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
      'https://whisper-2nhg.onrender.com/api/comment/confession/${widget.confessionId}?page=1&size=30',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          comments = List<Map<String, dynamic>>.from(data['comments']);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> postComment() async {
    String text = _commentController.text.trim();
    if (text.isEmpty || userId.isEmpty) return;

    setState(() => isPosting = true);

    if (quotedUsername != null && !text.startsWith('@$quotedUsername')) {
      text = '@$quotedUsername $text';
    }

    final url = Uri.parse('https://whisper-2nhg.onrender.com/api/comment/add');
    final body = {
      "confessionId": widget.confessionId,
      "text": text,
      "username": username,
      "authorId": userId,
      "quotedCommentId": quotedCommentId ?? "",
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newComment = Map<String, dynamic>.from(data['comment']);
        print(newComment);

        socket.emit('sendComment', {
          ...newComment,
          'confessionId': widget.confessionId,
        });

        if (widget.onNewComment != null) {
          widget.onNewComment!();
        }

        setState(() {
          _commentController.clear();
          quotedCommentId = null;
          quotedUsername = null;
        });
      }
    } catch (e) {
      // Handle silently
    } finally {
      setState(() => isPosting = false);
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    _commentController.dispose();
    super.dispose();
  }

  String formatTimeAgo(String isoDate) {
    final dateTime = DateTime.tryParse(isoDate)?.toLocal();
    if (dateTime == null) return '';
    final duration = DateTime.now().difference(dateTime);
    if (duration.inSeconds < 60) return 'just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }

  Map<String, List<Map<String, dynamic>>> groupCommentsByParent() {
    Map<String, List<Map<String, dynamic>>> tree = {};
    for (var comment in comments) {
      String parentId = 'root';

      if (comment['quotedCommentId'] != null) {
        if (comment['quotedCommentId'] is String) {
          parentId = comment['quotedCommentId'];
        } else if (comment['quotedCommentId'] is Map &&
            comment['quotedCommentId']['_id'] != null) {
          parentId = comment['quotedCommentId']['_id'];
        }
      }

      if (!tree.containsKey(parentId)) {
        tree[parentId] = [];
      }
      tree[parentId]!.add(comment);
    }
    return tree;
  }

  List<Widget> buildCommentTree(
    Map<String, List<Map<String, dynamic>>> tree,
    String parentId,
    int indentLevel,
  ) {
    if (!tree.containsKey(parentId)) return [];

    List<Widget> widgets = [];
    for (var comment in tree[parentId]!) {
      String id = comment['_id'];

      widgets.add(
        _buildCommentItem(
          context: context,
          name: comment['username'] ?? 'Anonymous',
          time: formatTimeAgo(comment['createdAt'] ?? ''),
          text: comment['text'] ?? '',
          commentId: id,
          indentLevel: indentLevel,
        ),
      );

      widgets.addAll(buildCommentTree(tree, id, indentLevel + 1));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final commentTree = groupCommentsByParent();

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : comments.isEmpty
              ? Center(
                  child: Text(
                    'No comments yet',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                )
              : ListView(
                  children: buildCommentTree(commentTree, 'root', 0),
                  padding: EdgeInsets.zero,
                ),
        ),
        if (quotedUsername != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Replying to ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextSpan(
                          text: '@$quotedUsername',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      quotedCommentId = null;
                      quotedUsername = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: GoogleFonts.inter(fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              isPosting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: postComment,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem({
    required BuildContext context,
    required String name,
    required String time,
    required String text,
    required String commentId,
    int indentLevel = 0,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (indentLevel > 0)
            Container(
              width: 16,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  Expanded(child: Container(width: 2, color: Colors.grey[300])),
                  Container(width: 12, height: 2, color: Colors.grey[300]),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16 + indentLevel * 8.0, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?u=user',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              time,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildCommentText(text),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        quotedCommentId = commentId;
                        quotedUsername = name;
                        _commentController.text = '@$name ';
                        _commentController
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: _commentController.text.length),
                        );
                      });
                    },
                    child: Text(
                      'Reply',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
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

  Widget _buildCommentText(String text) {
    final mentionRegex = RegExp(r'(@\w+)');
    final spans = <TextSpan>[];

    int lastMatchEnd = 0;

    final matches = mentionRegex.allMatches(text);

    if (matches.isEmpty) {
      // No mention, render entire text normally
      spans.add(TextSpan(text: text, style: GoogleFonts.inter(fontSize: 14)));
    } else {
      for (final match in matches) {
        if (match.start > lastMatchEnd) {
          // Add normal text before mention
          spans.add(
            TextSpan(
              text: text.substring(lastMatchEnd, match.start),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          );
        }

        // Add mention with blue color
        spans.add(
          TextSpan(
            text: match.group(0),
            style: GoogleFonts.inter(fontSize: 14, color: Colors.blue),
          ),
        );

        lastMatchEnd = match.end;
      }

      // Add remaining text after last mention
      if (lastMatchEnd < text.length) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd),
            style: GoogleFonts.inter(fontSize: 14),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
        children: spans,
      ),
    );
  }
}
