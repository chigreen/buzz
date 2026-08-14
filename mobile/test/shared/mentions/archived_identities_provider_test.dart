import 'package:flutter_test/flutter_test.dart';
import 'package:buzz/shared/mentions/archived_identities_provider.dart';
import 'package:buzz/shared/relay/relay.dart';

NostrEvent _snapshot(List<List<String>> tags) => NostrEvent(
  id: 'id',
  pubkey: 'f' * 64,
  createdAt: 1700000000,
  kind: 13535,
  tags: tags,
  content: '',
  sig: 'sig',
);

void main() {
  group('archivedPubkeysFromSnapshot', () {
    test('collects lowercase 64-hex p tags', () {
      final upper = 'A' * 64;
      final archived = archivedPubkeysFromSnapshot(
        _snapshot([
          ['p', 'a' * 64],
          ['p', upper],
          ['p', 'b' * 64, 'extra'],
        ]),
      );
      expect(archived, {'a' * 64, 'b' * 64});
    });

    test('ignores malformed tags and non-hex pubkeys', () {
      final archived = archivedPubkeysFromSnapshot(
        _snapshot([
          ['p'],
          ['p', 'too-short'],
          ['p', 'g' * 64],
          ['e', 'a' * 64],
          ['-'],
        ]),
      );
      expect(archived, isEmpty);
    });
  });
}
