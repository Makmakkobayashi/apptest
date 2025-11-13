import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'login.dart';
import 'diary_entry.dart';

class DiaryHomePage extends StatefulWidget {
  static const String id = 'DiaryHomePage';
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late CollectionReference _diaryCollection;
  late DatabaseReference _diaryRtdbRef;
  List<DiaryEntry> _entries = [];
  StreamSubscription<QuerySnapshot>? _diarySubscription;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  void _initDatabase() {
    final user = _auth.currentUser;
    if (user != null) {
      _diaryCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('diary');
      _diaryRtdbRef = FirebaseDatabase.instance.ref('users/${user.uid}/diary');
      _diarySubscription = _diaryCollection.snapshots().listen((snapshot) {
        final entries = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          DateTime createdDate;
          DateTime lastAccessedDate;
          try {
            createdDate = (data['createdDate'] as Timestamp).toDate();
          } catch (e) {
            createdDate = DateTime.now();
          }
          try {
            lastAccessedDate = (data['lastAccessedDate'] as Timestamp).toDate();
          } catch (e) {
            lastAccessedDate = DateTime.now();
          }
          return DiaryEntry(
            id: doc.id,
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            createdDate: createdDate,
            lastAccessedDate: lastAccessedDate,
          );
        }).toList();
        setState(() {
          _entries = entries;
        });
      });
    }
  }

  void _addNewEntry(Map<String, dynamic> entry) {
    final newEntryRef = _diaryCollection.doc();
    final newRtdbRef = _diaryRtdbRef.child(newEntryRef.id);

    newEntryRef.set(entry);
    newRtdbRef.set(entry);
  }

  void _updateEntry(String id, Map<String, dynamic> entry) {
    _diaryCollection.doc(id).update(entry);
    _diaryRtdbRef.child(id).update(entry);
  }

  void _deleteEntry(String id) {
    _diaryCollection.doc(id).delete();
    _diaryRtdbRef.child(id).remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26282B),
      appBar: AppBar(
        title: const Text(
          'My Diary',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF26282B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _auth.signOut();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _entries.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.white54),
                  SizedBox(height: 20),
                  Text(
                    'No entries yet',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap the + button to create your first entry!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Card(
                  color: const Color(0xFF3A3D42),
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _editEntry(entry),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(entry),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.content.length > 120
                                ? '${entry.content.substring(0, 120)}...'
                                : entry.content,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(entry.createdDate),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white54,
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewEntry,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF26282B),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Entry',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _createNewEntry() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiaryEntryPage()),
    );
    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      _addNewEntry(result);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('New entry added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editEntry(DiaryEntry entry) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DiaryEntryPage(entry: entry)),
    );
    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      _updateEntry(entry.id, result);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Entry updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmDelete(DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A3D42),
          title: const Text(
            'Delete Entry',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${entry.title}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                _deleteEntry(entry.id);
                Navigator.of(context).pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Entry deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _diarySubscription?.cancel();
    super.dispose();
  }
}

class DiaryEntryPage extends StatefulWidget {
  final DiaryEntry? entry;

  const DiaryEntryPage({super.key, this.entry});

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    isEditing = widget.entry != null;

    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26282B),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Entry' : 'New Entry',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF26282B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3A3D42),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter title...',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3D42),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _contentController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Write your thoughts here...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3D42),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (isEditing) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Created: ${_formatDate(widget.entry!.createdDate)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last accessed: ${_formatDate(widget.entry!.lastAccessedDate)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Today: ${_formatDate(DateTime.now())}',
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _saveEntry() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String title = _titleController.text.trim();
    String content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final entryData = {
      'title': title,
      'content': content,
      'createdDate': isEditing
          ? widget.entry!.createdDate.toIso8601String()
          : DateTime.now().toIso8601String(),
      'lastAccessedDate': DateTime.now().toIso8601String(),
    };

    Navigator.pop(context, entryData);
  }
}
