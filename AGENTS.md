# Repository guidance

## Setup and verification
- Run commands from the repository root. `pubspec.yaml` requires Dart `^3.13.0`; `pubspec.lock` requires Flutter `>=3.44.0`. README's Flutter version requirement is misleading.
- If `.env` is absent, run `cp .env.example .env` and configure it before `flutter pub get`. `.env` is a declared Flutter asset even though startup catches load errors. It is gitignored but bundled in the app; do not treat its values as private server secrets.
- After dependency resolution: `flutter analyze --no-pub` checks lint and types; `flutter test --no-pub` runs tests. No separate typecheck command.
- Focused test: `flutter test --no-pub test/download_service_test.dart`. This suite binds a loopback HTTP server and uses temporary Hive storage plus mocked platform channels; sandbox restrictions can block it.
- `test/widget_test.dart` is a placeholder assertion, not an app smoke test. Use the feature-specific suites for meaningful coverage.
- Android build check: `flutter build apk --debug --no-pub`. Release builds currently use debug signing (`android/app/build.gradle.kts`); `flutter build apk --release` does not produce a production-signed artifact.

## Wiring and boundaries
- Dependencies are registered manually in `lib/injection_container.dart` using GetIt: services/repositories/use cases are generally lazy singletons, BLoCs/Cubits factories. Update registrations there; installed `injectable` and `build_runner` packages do not mean DI is generated.
- Preserve startup dependencies in `lib/main.dart`: environment/media initialization, Hive boxes, download/tracking/notification services, DI registration, then background sync and app launch. Services cannot assume these steps have already run in isolated tests.
- Shared BLoC providers live in `lib/app/app.dart`; navigation lives in `lib/app/router.dart`. Its indexed stack preserves the five tab branches; detail/player routes use the root navigator.
- Features generally separate `data`, `domain`, and `presentation`, but downloads/settings are not uniformly layered. Follow the touched feature rather than imposing README's strict architecture claim.
- Shared HTTP setup lives in `lib/core/network/dio_client.dart`: Anizium headers, auth, memory cache, then error conversion. Base URLs/environment access live in `lib/core/constants/api_constants.dart`.
