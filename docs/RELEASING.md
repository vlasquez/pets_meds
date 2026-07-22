# Releasing Pet Meds

## How a release works

Releases are triggered manually and the version bump is automatic:

1. GitHub → **Actions** → **Release** → **Run workflow**.
2. Pick the **Version bump**:
   - `patch` → 1.0.0 → 1.0.1 (bug fixes)
   - `minor` → 1.0.0 → 1.1.0 (new features)
   - `major` → 1.0.0 → 2.0.0 (breaking changes)
3. The workflow computes the next version from `pubspec.yaml`, updates
   it, commits, and tags `vX.Y.Z`. Then it runs tests, builds the signed
   Android App Bundle (versionName = the new version, versionCode = the
   run number), uploads it to the **Play internal track**, and publishes
   a **GitHub Release** with the .aab and .apk attached.
4. Promote the Play release to production from the Play Console.
5. iOS: CI verifies the build compiles. TestFlight uploads are manual
   for now (`flutter build ipa` + Transporter) — see below to automate.

Note: if `main` is a protected branch, the version-bump *commit* may be
rejected (the tag is still created and the build still uses the correct
version). To let the bot commit to `main`, allow the
`github-actions[bot]` actor to bypass the branch rule, or pull the
version commit locally afterwards.

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
