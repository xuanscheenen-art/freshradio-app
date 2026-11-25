# Fresh Radio app

Flutter-app (iOS + Android) voor Fresh Radio: live speler, nummer dat nu speelt
met albumhoes, laatst gedraaide nummers, een slaaptimer en de
Fresh Radio Charts (week, maand, jaar). Afspelen gaat door
op de achtergrond, met bediening via het vergrendelscherm en de koptelefoon.

## Waar de data vandaan komt

| Wat | Bron |
|---|---|
| Stream | `https://server7.radio-streams.net/proxy/jcikurvb/stream` (Shoutcast, MP3 320 kbps) |
| Nu + laatst gedraaid | `https://server7.radio-streams.net/proxy/jcikurvb/played?sid=1&type=json`, elke 15 s |
| Albumhoes | iTunes Search API |
| Charts | `https://freshradio.nl/wp-json/fresh-radio/v1/charts?period=week\|month\|year` |

Alles wat per station verschilt staat in `lib/src/station_config.dart`.
Voor een app van een ander station pas je alleen dat bestand en
`assets/logo.png` aan.

## Starten op een Mac

1. Installeer Xcode (Mac App Store) en open het één keer.
2. Installeer Flutter: https://docs.flutter.dev/get-started/install/macos
3. In deze map:

   ```bash
   flutter pub get
   flutter test
   flutter run
   ```

   `flutter run` start de app op een aangesloten iPhone, de iOS-simulator of
   een Android-telefoon.

## Code

- `lib/main.dart`: opstarten, audio-service, thema
- `lib/src/radio_audio_handler.dart`: speler en vergrendelscherm
- `lib/src/now_playing.dart`: nu-speelt-informatie en albumhoezen
- `lib/src/app_shell.dart`: tabbladen Live en Charts, mini-speler
- `lib/src/home_screen.dart`: het Live-scherm
- `lib/src/charts.dart`, `lib/src/charts_screen.dart`: de charts
- `lib/src/track.dart`: "Artiest - Titel" uit de streamdata halen
- `test/`: tests

## Nog te doen voor de stores

- App-icoon (vierkant logo nodig)
- Bundle ID / applicationId definitief maken (nu `nl.freshradio.freshradio_app`)
- Privacyverklaring op freshradio.nl
- Store-teksten en screenshots
