# Finar

A modern Jellyfin client written in Flutter. Targets Android, iOS, Linux, Windows, macOS and web.

- Refactor rather than duplicating code.
- Goal is an A+ codebase: small files, clear ownership, no god files.
- Every code change needs a real test. Tests must exercise the actual change, not just pass.
- Golden tests live in test/golden/ and cover every page. Regenerate with `flutter test --update-goldens`.
- Run `flutter analyze` (must be clean) and `flutter test --coverage` before committing.
- Shell script changes get a matching case in test/scripts/.
- User-facing strings go through ARB localisation (en_GB template, zh, ru, ga). Never hardcode UI text.
- Secrets, keystores and signing keys never go in the repo.

## Repo rules

1. Do not leak any api keys or jks keys at all. (note their is a harcoded api key for ytm that api key is not a actural real api key)
2. Do not write god files refactor stuff if you have to.
3. Do not use em dashes and other ai grabage writing no one wants to read AI Slop.
4. Do not run the app eg. flutter run -d linux The devloper will do this.
5. Write tests for EVERY new thing you do any code change should be testable no matter how small it is write the test. Make sure tests are created just to pass they should test the actural changes. EXPECT for non-code changes editing a md file or linaece file or anything that is not a actural code change no test is needed and should not be written.
6. Ensure all tests pass after any change.
7. When opening a merge request in the body include what model, provider and the harness used to create the merge request. If the code was human made then state "Created by human, PR created with ...."
8. When opening a new merge request make sure to update the changelog.md file for the change you did UNLESS its not a code change. Make sure it is listed under the same version in the pubspec version.
