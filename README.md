# Vault - Secure Session & Encrypted Storage

A Flutter take-home demonstrating an encrypted offline profile cache, a PBKDF2
app-lock PIN, and a single-flight token refresh against the public DummyJSON API.

## Running

```bash
flutter pub get
flutter run          # Android or iOS device/emulator. Web is not supported.
```

Test credentials: `emilys` / `emilyspass`.

Login requests `expiresInMins: 1`, so the access token expires roughly a minute
after sign-in and `GET /auth/me` starts returning 401. Leave the app on the
Profile screen for a minute and pull to refresh to watch the interceptor renew
the session without the UI noticing.

## Architecture

Feature-first clean architecture. Each feature owns its own `data`, `domain` and
`presentation` layers; cross-cutting infrastructure lives in `core`.

```
lib/
  core/
    constants/   app + API configuration
    crypto/      AES-256-GCM cache cipher, PBKDF2 PIN hasher
    di/          composition root
    error/       Failure type
    network/     Dio client, auth interceptor, token store
    storage/     secure storage and SharedPreferences wrappers
    theme/       Material 3 light/dark themes
    widgets/     shared presentation widgets
  features/
    app/         session state, lifecycle gate, root routing, home shell
    auth/        login + logout
    onboarding/  splash + intro
    profile/     online and offline profile
    security/    app-lock PIN: set, change, unlock
    settings/    theme, PIN management, logout
```

Dependency direction is `presentation -> domain <- data`. Presentation talks to
repository interfaces defined in `domain` and never constructs a Dio call or
touches the crypto layer. `core/di/injector.dart` is the only place the concrete
implementations are wired together.

State management is `flutter_bloc` (Cubit). Every async path exposes explicit
loading / success / failure states.

## Security

### Encrypted profile cache

Each successful `/auth/me` writes `profile.enc` in the app documents directory.
The file layout is a single binary blob:

```
[ 12-byte nonce ][ ciphertext ][ 16-byte GCM tag ]
```

* **AES-256-GCM**, an authenticated mode, so the tag is produced and verified as
  part of the cipher rather than bolted on.
* The 256-bit data key is generated from `Random.secure()` on first use and
  stored only in `flutter_secure_storage`. It is never a constant in source,
  never derived from the username, and never committed.
* A fresh random nonce per write means encrypting the same profile twice
  produces two byte-different files.
* On read, a failed authentication tag is treated as a **cache miss**, not as an
  error surfaced to the user. The same applies to a missing key or malformed
  JSON.

Opening `profile.enc` in a text editor shows binary noise; the email address is
not recoverable from it.

### App lock PIN

* Stored as a **PBKDF2-HMAC-SHA256** derivation with a 16-byte random salt and
  120,000 iterations. The PIN itself is never written to storage, and neither is
  a bare hash of it.
* A six-digit PIN is only a million values, so an unsalted digest would fall to
  a rainbow table instantly; the salt and iteration count are what make an
  offline sweep expensive.
* Verification is constant time - the comparison folds the length difference
  into the accumulator and examines every byte, so a failed unlock does not leak
  how much of the hash matched.
* Derivation runs in a background isolate, so the UI does not stall while the
  iterations run.
* Three consecutive wrong attempts force a logout.
* Entry uses a custom on-screen keypad; the system keyboard is never shown.

### Token lifecycle

* Both tokens live in `flutter_secure_storage`, never in a plain file or
  SharedPreferences.
* `AuthInterceptor` injects the `Authorization: Bearer` header on every
  authenticated call.
* On a 401 it refreshes once and retries the original request once. A request
  that has already been retried carries a flag and gives up instead of looping.
* **Single-flight**: a single `Future<bool>?` field holds the refresh in
  progress. If three requests fail with 401 at the same moment, the first starts
  the refresh and the other two await the same future - exactly one
  `POST /auth/refresh` goes out, then all three retry.
* If the refresh itself fails, every stored secret is wiped and the app returns
  to Login with a message.

### Storage separation

Sensitive values (tokens, cache key, PIN salt and hash) go to
`flutter_secure_storage`, which is Keystore/Keychain backed. Non-sensitive flags
(intro seen, selected theme) go to `SharedPreferences`. The split is deliberate.

## Cold-start routing

Decided on the splash screen from local storage only, with no network call and a
maximum 1.5s budget. The root widget swaps the entire tree rather than pushing
routes, so neither Splash nor Login is reachable with the back button.

| Stored state                  | Destination         |
| ----------------------------- | ------------------- |
| No token, intro never seen    | Intro, then Login   |
| No token, intro already seen  | Login               |
| Token present, PIN set        | PIN Lock, then Profile |
| Token present, no PIN         | Profile             |

The PIN lock is raised by a `WidgetsBindingObserver` on
`AppLifecycleState.paused` and renders as a full-screen opaque layer above the
home shell, which is taken off-stage while locked - no glimpse of Profile behind
it.

## Offline behaviour

On a network failure the profile repository falls back to the decrypted cache
and the screen renders the same layout with an offline banner and the last
synced time. With no usable cache it shows an error state with a working
"Try again". Toggling aeroplane mode on and off recovers without restarting the
app.

A dead session is deliberately *not* papered over by the cache: an expired
session that could not be refreshed sends the user back to Login.

## Tests

```bash
flutter test
```

1. `test/encrypted_cache_test.dart` - AES-GCM round-trip, proof that two
   encryptions of the same input differ, that the plaintext email is not present
   in the ciphertext, and that a tampered tag or wrong key reads as a miss.
2. `test/pin_hasher_test.dart` - the right PIN verifies, a wrong one does not,
   the stored value is not the PIN, and the salt makes each derivation unique.
3. `test/token_refresh_test.dart` - one 401 causes exactly one refresh call and
   exactly one retry, with the retry carrying the new bearer token. Mocked, no
   network.

## Analyzer

```bash
dart analyze
```

Reports zero issues.

## Notes

* Biometrics are deliberately out of scope; `local_auth` is not used.
* Web is not supported - secure storage behaves differently there.
* No `.env`, keystore or key material is included in this repository.
