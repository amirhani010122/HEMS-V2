extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncate string to max length
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Format phone number
  String formatPhone() {
    final digits = replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return this;
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
  }

  /// Check if valid email
  bool isValidEmail() {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Convert to slug
  String toSlug() {
    return toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'[-\s]+'), '-');
  }
}

extension DateTimeExtension on DateTime {
  /// Format as "MMM dd, yyyy"
  String formatDate() {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${monthNames[month - 1]} $day, $year';
  }

  /// Format as "HH:mm"
  String formatTime() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Format as "MMM dd, yyyy HH:mm"
  String formatDateTime() {
    return '${formatDate()} ${formatTime()}';
  }

  /// Time ago format
  String timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} year${(diff.inDays / 365).floor() > 1 ? 's' : ''} ago';
    }
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} month${(diff.inDays / 30).floor() > 1 ? 's' : ''} ago';
    }
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    return 'Just now';
  }

  /// Check if is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Get start of day
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get end of day
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// Get start of month
  DateTime get startOfMonth {
    return DateTime(year, month);
  }

  /// Get end of month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }
}

extension NumExtension on num {
  /// Format number with 2 decimal places
  String toStringWithDecimals([int decimals = 2]) {
    return toStringAsFixed(decimals);
  }

  /// Format as currency
  String formatCurrency([String symbol = '\$']) {
    return '$symbol${toStringAsFixed(2)}';
  }

  /// Format as percentage
  String formatPercent([int decimals = 1]) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Format number with thousands separator
  String formatNumber() {
    return toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match m) => ',',
    );
  }

  /// Convert to bytes (file size)
  String formatBytes() {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(2)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

extension ListExtension<T> on List<T> {
  /// Get first or null
  T? get firstOrNull {
    return isEmpty ? null : first;
  }

  /// Get last or null
  T? get lastOrNull {
    return isEmpty ? null : last;
  }

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  /// Check if list contains any element matching condition
  bool anyWhere(bool Function(T) test) {
    return any(test);
  }

  /// Get unique elements
  List<T> unique([dynamic Function(T)? getCompare]) {
    final ids = <dynamic>{};
    final list = <T>[];
    for (var i = 0; i < length; i++) {
      final id = getCompare != null ? getCompare(this[i]) : this[i];
      if (!ids.contains(id)) {
        ids.add(id);
        list.add(this[i]);
      }
    }
    return list;
  }
}
