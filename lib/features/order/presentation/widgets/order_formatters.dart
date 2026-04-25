String formatRupiah(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < raw.length; index++) {
    final reverseIndex = raw.length - index;
    buffer.write(raw[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'Rp ${buffer.toString()}';
}

String formatDateTimeLong(DateTime? dateTime) {
  if (dateTime == null) {
    return '-';
  }

  final local = dateTime.toLocal();
  final month = _monthAbbreviation(local.month);
  final day = local.day.toString().padLeft(2, '0');
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month $year, $hour:$minute';
}

String formatDateTimeShort(DateTime? dateTime) {
  if (dateTime == null) {
    return '-';
  }

  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

String formatCountdown(Duration duration) {
  if (duration.isNegative || duration == Duration.zero) {
    return '00:00';
  }

  final totalSeconds = duration.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String formatAttributeKey(String rawKey) {
  final words = rawKey
      .split('_')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => _capitalize(part.trim()))
      .toList();

  if (words.isEmpty) {
    return rawKey;
  }

  return words.join(' ');
}

String formatAttributeValue(String rawValue) {
  final words = rawValue
      .split('_')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => _capitalize(part.trim()))
      .toList();

  if (words.isEmpty) {
    return rawValue;
  }

  return words.join(' ');
}

String _monthAbbreviation(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  if (month < 1 || month > 12) {
    return '---';
  }

  return months[month - 1];
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}
