# Android release signing for NOOR

NOOR uses the same Android application ID across updates. Android accepts an in-place update only when the new APK is signed with the same signing identity as the installed release.

## If NOOR has already been distributed

Use the **original** `.jks` / `.keystore` file, original alias, and original passwords. Do not generate a replacement key. A different key prevents Android from installing the new APK as an update over the existing app.

## Configure GitHub Actions

1. Open the repository on GitHub.
2. Go to **Settings → Secrets and variables → Actions → New repository secret**.
3. Add these four repository secrets:

| Secret name | Value |
|---|---|
| `KEYSTORE_BASE64` | Base64 text of the original JKS/keystore file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Existing key alias |
| `KEY_PASSWORD` | Password for that alias |

On Linux, produce the base64 value locally with:

```bash
base64 -w 0 path/to/noor-release.jks
```

On macOS:

```bash
base64 < path/to/noor-release.jks | tr -d '\n'
```

Paste the resulting text only into the `KEYSTORE_BASE64` secret. Never commit the keystore, its passwords, or `android/key.properties` to Git.

## Verify the alias before configuring secrets

```bash
keytool -list -v -keystore path/to/noor-release.jks
```

Confirm the alias and certificate fingerprint match the key used for the installed release. Keep an encrypted offline backup of the keystore and its credentials.

## First release only

If NOOR has **never** been distributed or installed from a release-signed APK, a new signing key may be generated. Once the first release is signed, that key must be preserved for every future update.

Pull-request builds use a temporary CI key only for compilation checks. They are not production-installable updates and their signatures are intentionally not reused.
