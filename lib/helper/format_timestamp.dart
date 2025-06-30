import 'package:intl/intl.dart';

String formatTimestamp(String isoString) {
  try {
    DateTime dateTime = DateTime.parse(isoString).toLocal();
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago'; // corrected here
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago'; // corrected here
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  } catch (e) {
    return isoString; // fallback if parsing fails
  }
}
