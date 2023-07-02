# Messages over nostr protocol (WIP, no release yet)

Built upon nip04 encrypted directed messages. Nostr channels are next up.

Demo is running at https://ntheden.github.io/demo-site


To build and run:

Linux & Web App
===
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs -o web:build/web/
flutter run
```


Android
===
```
flutter build apk
```
