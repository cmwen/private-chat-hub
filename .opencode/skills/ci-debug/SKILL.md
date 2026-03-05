---
name: ci-debug
description: Debug GitHub Actions workflow failures, CI build issues, test failures in CI, and deployment problems
---

# CI / GitHub Actions Debugging

Expert guidance for debugging GitHub Actions workflows and CI-specific issues for this Flutter Android project.

## When to Use

- GitHub Actions workflow failures
- CI build errors that don't occur locally
- Test failures only in CI
- Artifact upload/download issues
- Secret/credential problems
- Cache-related failures

## Project Workflows

### build.yml (Main CI)
- Triggers: push to main/develop, PRs
- Auto-formats with `dart format` and commits
- Applies `dart fix --apply`
- Builds APK and App Bundle
- Runs tests with coverage
- Uses `android/gradle-ci.properties`

### release.yml
- Triggers: version tags (v*)
- Signed release builds
- Creates GitHub Release
- Requires signing secrets

### pre-release.yml
- Manual dispatch for beta/alpha

## Debugging Steps

### 1. Access Logs
```bash
gh run list --limit 10        # Recent runs
gh run view <run-id>          # View specific run
gh run download <run-id>      # Download logs
```

### 2. Common Failures

**Flutter/Dart Setup**: Check flutter-action version in workflow matches project needs (3.38.3+)

**Java Version**: Must be 17. Verify `setup-java` action uses `java-version: '17'`

**Gradle OOM**: CI uses `gradle-ci.properties` (3GB heap, 2 workers, no daemon). Verify `cp android/gradle-ci.properties android/gradle.properties` step exists.

**Dependency Resolution**: Clear cache by changing cache key. Check `pubspec.yaml` validity.

**Test Failures (CI-only)**:
- Timing issues - ensure proper `await` usage
- File paths must be relative, not absolute
- No external service dependencies
- Check timezone/locale differences

**Cache Issues**: Verify key `${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}`. 10GB limit per repo.

**Auto-format Commit**: Requires `GITHUB_TOKEN` write permissions. Only runs on same-repo PRs.

### 3. Release Issues

**Missing Secrets** (required for release.yml):
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

**Tag Not Triggering**: Must start with `v` (e.g., `v1.0.0`)

## Local CI Simulation
```bash
cp android/gradle-ci.properties android/gradle.properties
flutter clean && flutter pub get
dart format . && dart fix --apply
flutter analyze
flutter test --coverage
flutter build apk --release && flutter build appbundle --release
git checkout android/gradle.properties  # Restore local config
```

## Quick Checklist

- Flutter version matches workflow config?
- Java version is 17?
- `gradle-ci.properties` settings correct?
- All required secrets are set?
- Tests pass locally with same commands?
- Cache keys match lock file?
- Artifact paths match build output?
