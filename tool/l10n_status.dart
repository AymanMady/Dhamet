// Prints the translation status of each language.
//
//   dart run tool/l10n_status.dart            # summary
//   dart run tool/l10n_status.dart ar_MR      # list the missing messages
import 'dart:convert';
import 'dart:io';

Set<String> _messages(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return {
    for (final key in json.keys)
      if (!key.startsWith('@')) key,
  };
}

void main(List<String> arguments) {
  final directory = Directory('lib/l10n');
  final template = _messages(File('${directory.path}/app_fr.arb'));
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final locale = file.uri.pathSegments.last
        .replaceFirst('app_', '')
        .replaceFirst('.arb', '');
    final missing = template.difference(_messages(file)).toList()..sort();
    final fallback = locale.contains('_')
        ? ' (falls back to ${locale.split('_').first})'
        : '';
    stdout.writeln(
      '$locale: ${template.length - missing.length}/${template.length} '
      'translated$fallback',
    );
    if (arguments.contains(locale)) {
      for (final key in missing) {
        stdout.writeln('  - $key');
      }
    }
  }
}
