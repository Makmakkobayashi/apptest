class TodoItem {
  final String id;
  String title;
  String description;
  bool isCompleted;
  final DateTime createdDate;

  TodoItem({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdDate,
  });

  void toggleComplete() {
    isCompleted = !isCompleted;
  }
}