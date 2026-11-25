import 'package:flutter_test/flutter_test.dart';
import 'package:freshradio_app/src/track.dart';

void main() {
  test('splits artist and title', () {
    final t = Track.fromMetadata('DJ Piero - Another World (Radio Mix)');
    expect(t.artist, 'DJ Piero');
    expect(t.title, 'Another World (Radio Mix)');
    expect(t.searchTitle, 'Another World');
    expect(t.isStationId, isFalse);
  });

  test('keeps dashes inside the title', () {
    final t = Track.fromMetadata('Modern Talking - No Face - No Name');
    expect(t.artist, 'Modern Talking');
    expect(t.title, 'No Face - No Name');
  });

  test('metadata without a separator becomes the title', () {
    final t = Track.fromMetadata('Fresh Radio Live');
    expect(t.artist, '');
    expect(t.title, 'Fresh Radio Live');
  });

  test('recognises station IDs', () {
    final t = Track.fromMetadata('Fresh Radio - Day starts here',
        stationIdArtists: ['Fresh Radio']);
    expect(t.isStationId, isTrue);
  });

  test('search artist drops featured artists', () {
    expect(Track.fromMetadata('MC Sar & The Real McCoy - Automatic Lover')
        .searchArtist, 'MC Sar');
    expect(Track.fromMetadata('Tiësto feat. Nelly Furtado - Who Wants To Be Alone')
        .searchArtist, 'Tiësto');
  });

  test('parses the Shoutcast played JSON', () {
    final list = Track.listFromPlayedJson([
      {'playedat': 1795598524, 'title': 'DJ Piero - Another World (Radio Mix)'},
      {'playedat': 1795598072, 'title': 'Fresh Radio - Day starts here'},
      {'playedat': 1795597875},
      'garbage',
    ], stationIdArtists: ['Fresh Radio']);
    expect(list.length, 2);
    expect(list.first.playedAt,
        DateTime.fromMillisecondsSinceEpoch(1795598524 * 1000));
    expect(list[1].isStationId, isTrue);
  });
}
