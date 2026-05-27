DateTime? parseChatTimeInThailand(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;

  try {
    final normalized = text.replaceFirst(' ', 'T');
    final hasTimezone = normalized.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(normalized);
    final utcTime = DateTime.parse(hasTimezone ? normalized : '${normalized}Z');
    return utcTime.toUtc().add(Duration(hours: hasTimezone ? 14 : 7));
  } catch (_) {
    return null;
  }
}

String formatChatClockInThailand(String? raw) {
  final text = raw?.trim() ?? '';
  final hasTimezone =
      text.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(text);
  if (hasTimezone) {
    final dt = parseChatTimeInThailand(raw);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  final match =
      RegExp(r'(?:^|\D)(\d{1,2}):(\d{2})(?::\d{2})?').firstMatch(text);
  if (match != null) {
    final utcHour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (utcHour != null && minute != null) {
      final thaiHour = (utcHour + 7) % 24;
      return '${thaiHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
  }

  final dt = parseChatTimeInThailand(raw);
  if (dt == null) return '';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
