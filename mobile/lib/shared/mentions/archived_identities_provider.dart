import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../relay/relay.dart';

/// Extract archived pubkeys from a NIP-IA `kind:13535` snapshot event.
///
/// Mirrors desktop's `archived_pubkeys_from_snapshot`: archived identities
/// are the snapshot's `p` tags, kept only when they are 64-char hex.
Set<String> archivedPubkeysFromSnapshot(NostrEvent snapshot) {
  final archived = <String>{};
  for (final tag in snapshot.tags) {
    if (tag.length < 2 || tag[0] != 'p') continue;
    final pk = tag[1].toLowerCase();
    if (pk.length != 64) continue;
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(pk)) continue;
    archived.add(pk);
  }
  return archived;
}

/// Pubkeys in the relay's NIP-IA archive snapshot (`kind:13535`).
///
/// Drives hiding archived identities from forward-looking discovery surfaces
/// (mention autocomplete), mirroring desktop's `useIsArchivedPredicate`.
/// Fail-open: a disconnected session, a missing snapshot, or a fetch error
/// all resolve to an empty set so a cold start can't briefly hide everyone.
/// Trusts the home relay's own list events over the authenticated session,
/// like the `kind:13534` membership fallback in `pulse_provider.dart`.
final archivedIdentitiesProvider = FutureProvider<Set<String>>((ref) async {
  final sessionState = ref.watch(relaySessionProvider);
  if (sessionState.status != SessionStatus.connected) return const {};
  final session = ref.read(relaySessionProvider.notifier);
  final events = await session.fetchHistory(NostrFilters.archivedIdentities());
  final snapshots = [
    for (final event in events)
      if (event.kind == 13535) event,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (snapshots.isEmpty) return const {};
  return archivedPubkeysFromSnapshot(snapshots.first);
});
