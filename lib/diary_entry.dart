class DiaryEntry {
  final String id;
  String title;
  String content;
  final DateTime createdDate;
  DateTime lastAccessedDate;
  final String? imagePath;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdDate,
    DateTime? lastAccessedDate,
    this.imagePath,
  }) : lastAccessedDate = lastAccessedDate ?? DateTime.now();

  void updateLastAccessed() {
    lastAccessedDate = DateTime.now();
  }

  // For backward compatibility with your existing code
  DateTime get date => createdDate;
}