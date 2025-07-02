import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void showCommentsModal(BuildContext context, String confessionId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: CommentsModalContent(confessionId: confessionId),
      );
    },
  );
}

class CommentsModalContent extends StatefulWidget {
  final String confessionId;
  const CommentsModalContent({super.key, required this.confessionId});

  @override
  State<CommentsModalContent> createState() => _CommentsModalContentState();
}

class _CommentsModalContentState extends State<CommentsModalContent> {
  bool isLoading = true;
  bool isPosting = false;
  List<Map<String, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();

  String username = 'Anonymous';
  String userId = '';
  String? quotedCommentId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchComments();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Anonymous';
      userId = prefs.getString('userId') ?? '';
    });
  }

  Future<void> fetchComments() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
      'https://whisper-2nhg.onrender.com/api/comment/confession/${widget.confessionId}?page=1&size=10',
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
        print('[fetchComments] Failed: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('[fetchComments] Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || userId.isEmpty) return;

    setState(() => isPosting = true);

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
        setState(() {
          comments.insert(0, newComment);
          _commentController.clear();
          quotedCommentId = null;
        });
      } else {
        print('Failed to post comment: ${response.body}');
      }
    } catch (e) {
      print('Error posting comment: $e');
    } finally {
      setState(() => isPosting = false);
    }
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void handleQuickReplyTap(String text) {
    _commentController.text = text;
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
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

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Most relevant',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(thickness: 0.6, height: 1),

        // Comments list or loader
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
              : ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];

                    // Safely parse quotedCommentId as Map or null
                    String? quotedUsername;
                    if (comment['quotedCommentId'] != null &&
                        comment['quotedCommentId'] is Map &&
                        comment['quotedCommentId']['username'] != null) {
                      quotedUsername = comment['quotedCommentId']['username'];
                    }

                    return _buildCommentItem(
                      context: context,
                      name: comment['username'] ?? 'Anonymous',
                      time: formatTimeAgo(comment['createdAt'] ?? ''),
                      text: comment['text'] ?? '',
                      commentId: comment['_id'],
                      quotedUsername: quotedUsername,
                    );
                  },
                ),
        ),

        const Divider(thickness: 0.6, height: 1),

        // Quick reply chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickReplyChip('Love this take'),
                _buildQuickReplyChip('Thanks for sharing'),
              ],
            ),
          ),
        ),

        // Add comment bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?u=user',
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildQuickReplyChip(String label) {
    return GestureDetector(
      onTap: () => handleQuickReplyTap(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildCommentItem({
    required BuildContext context,
    required String name,
    required String time,
    required String text,
    required String commentId,
    String? quotedUsername,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      overflow: TextOverflow.ellipsis,
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
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),

          // Show quoted username if different from comment author
          if (quotedUsername != null &&
              quotedUsername.isNotEmpty &&
              quotedUsername != name)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 4),
              child: Text(
                '@$quotedUsername',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Comment text without duplicated mention
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              (quotedUsername != null &&
                      quotedUsername.isNotEmpty &&
                      text.startsWith('@$quotedUsername'))
                  ? text.substring(quotedUsername.length + 2).trim()
                  : text,
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 4),
            child: Row(
              children: [
                Text(
                  'Like',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      quotedCommentId = commentId;
                      _commentController.text = '@$name ';
                      _commentController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _commentController.text.length),
                      );
                    });
                    print('Replying to commentId: $commentId by $name');
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
        ],
      ),
    );
  }
}
