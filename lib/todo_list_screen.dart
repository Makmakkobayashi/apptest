import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'dashboard.dart';
import 'todo_model.dart';

class TodoListScreen extends StatefulWidget {
  static const String id = 'TodoListScreen';
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late CollectionReference _todoCollection;
  late DatabaseReference _todoRtdbRef;
  List<TodoItem> _todoItems = [];
  StreamSubscription<QuerySnapshot>? _todoSubscription;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  void _initDatabase() {
    final user = _auth.currentUser;
    if (user != null) {
      _todoCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('todos');
      _todoRtdbRef = FirebaseDatabase.instance.ref('users/${user.uid}/todos');
      _todoSubscription = _todoCollection.snapshots().listen((snapshot) {
        final todos = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          DateTime createdDate;
          try {
            createdDate = (data['createdDate'] as Timestamp).toDate();
          } catch (e) {
            createdDate = DateTime.now();
          }
          return TodoItem(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            isCompleted: data['isCompleted'] ?? false,
            createdDate: createdDate,
          );
        }).toList();
        setState(() {
          _todoItems = todos;
        });
      });
    }
  }

  void _addTodoItem() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A3D42),
          title: const Text(
            'Add New Task',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _titleController.clear();
                _descriptionController.clear();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isNotEmpty) {

                  final newDocRef = _todoCollection.doc();

                  final newTodoFirestore = {
                    'title': _titleController.text.trim(),
                    'description': _descriptionController.text.trim(),
                    'isCompleted': false,
                    'createdDate': Timestamp.now(),
                  };
                  newDocRef.set(newTodoFirestore);

                  final newTodoRtdb = {
                    'title': _titleController.text.trim(),
                    'description': _descriptionController.text.trim(),
                    'isCompleted': false,
                    'createdDate': DateTime.now().toIso8601String(),
                  };
                  _todoRtdbRef.child(newDocRef.id).set(newTodoRtdb);


                  _titleController.clear();
                  _descriptionController.clear();

                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Task added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(25),
              ),
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleTodoComplete(TodoItem item) {
    _todoCollection.doc(item.id).update({'isCompleted': !item.isCompleted});
    _todoRtdbRef.child(item.id).update({'isCompleted': !item.isCompleted});
  }

  void _deleteTodoItem(TodoItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A3D42),
          title: const Text(
            'Delete Task',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${item.title}"?',
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
                final navigator = Navigator.of(context);

                _todoCollection.doc(item.id).delete();
                _todoRtdbRef.child(item.id).remove();

                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted'),
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
  Widget build(BuildContext context) {
    final incompleteTodos = _todoItems.where((item) => !item.isCompleted).toList();
    final completedTodos = _todoItems.where((item) => item.isCompleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF26282B),
      appBar: AppBar(
        title: const Text(
          'To-Do List',
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
      body: _todoItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 80, color: Colors.white54),
                  SizedBox(height: 20),
                  Text(
                    'No tasks yet',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap the + button to add your first task!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (incompleteTodos.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'PENDING TASKS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...incompleteTodos.map((item) => _buildTodoCard(item)),
                ],
                if (completedTodos.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'COMPLETED',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...completedTodos.map((item) => _buildTodoCard(item)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTodoItem,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF26282B),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTodoCard(TodoItem item) {
    return Card(
      color: const Color(0xFF3A3D42),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _toggleTodoComplete(item),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isCompleted ? Colors.green : Colors.white70,
                    width: 2,
                  ),
                  color: item.isCompleted ? Colors.green : Colors.transparent,
                ),
                child: item.isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: item.isCompleted ? Colors.white54 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: item.isCompleted
                            ? Colors.white38
                            : Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(item.createdDate),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isCompleted)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                onPressed: () => _deleteTodoItem(item),
              ),
          ],
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _todoSubscription?.cancel();
    super.dispose();
  }
}
