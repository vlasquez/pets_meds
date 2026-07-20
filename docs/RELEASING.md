# Releasing Pet Meds

## How a release works

1. Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+X` — the build number
   is overridden in CI by the workflow run number).
2. Commit, then tag and push:
   ```
   git tag v1.0.1
   git push origin main --tags
   ```
3. GitHub Actions (`.github/workflows/release.yml`) runs tests, builds
   the signed Android App Bundle, and uploads it to the **Play internal
   track**. Promote it to production from the Play Console.
4. iOS: CI verifies the build compiles. Actual TestFlight uploads are
   manual for now (`flutter build ipa` + Transporter) — see below to
   automate.

## One-time GitHub setup (repo → Settings → Secrets and variables → Actions)

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i android/upload-keystore.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | the password from `android/key.properties` |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON key of a Google Cloud service account (below) |

### Play service account

1. Play Console → Setup → API access → link a Google Cloud project.
2. In Google Cloud Console: IAM → Service Accounts → create one
   (e.g. `play-publisher`), create a **JSON key**, paste its contents
   into the `PLAY_SERVICE_ACCOUNT_JSON` secret.
3. Back in Play Console → Users and permissions → invite the service
   account email with **Release manager** permission for the app.
4. Note: the *first* `.aab` must be uploaded manually in the console;
   the API can only upload to apps that already exist.

## Automating iOS uploads later

Options, in order of least effort:

- **Codemagic** (free tier: 500 macOS min/month): native Flutter
  support, manages Apple certificates for you, uploads to TestFlight.
- **GitHub Actions + fastlane**: store an App Store Connect API key
  (`.p8`) and distribution certificate + provisioning profile as
  secrets, then `fastlane pilot upload`. More setup, fully in-repo.

Remember macOS runners consume free GitHub minutes at 10× on private
repos (~200 real minutes/month).
