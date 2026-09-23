// Small display formatters shared across screens.

/// Formats a byte count as a compact human-readable size, e.g. `1.5 MB`.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final decimals = (size < 10 && unit > 0) ? 1 : 0;
  return '${size.toStringAsFixed(decimals)} ${units[unit]}';
}

/// Groups an integer in threes, e.g. `1234` → `1,234`.
String formatThousands(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Writes [number] with Arabic-Indic digits, e.g. `12` → `١٢` (ayah numbers).
String toArabicDigits(int number) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number
      .toString()
      .split('')
      .map((e) => arabicDigits[int.parse(e)])
      .join();
}

/// Formats a countdown as `HH:MM`, clamping a time that has already passed to
/// `00:00`.
String formatCountdown(Duration d) {
  final clamped = d.isNegative ? Duration.zero : d;
  final h = clamped.inHours.toString().padLeft(2, '0');
  final m = (clamped.inMinutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
