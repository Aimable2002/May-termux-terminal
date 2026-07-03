# YourApp Terminal

A rebranded Termux (Android) + matching PC CLI, both running the same
shared script suite for AI chat and agent (OpenCode) modes — no backend,
no account, bring your own API key.

## Structure

```
yourapp/
├── install.sh       # universal installer — run this on PC (Linux/macOS) or inside Termux
├── bin/
│   ├── yourapp         # menu dispatcher — entrypoint
│   ├── yourapp-chat     # chat mode
│   ├── yourapp-agent    # launches OpenCode, configured with your key
│   ├── yourapp-models   # lists free/paid models from your provider
│   └── yourapp-config   # set your API key, base URL, default model
├── lib/
│   └── common.sh        # shared config read/write helpers
└── android/
    └── termux-apps/     # forked Termux Play Store repo, rebranded
                          # (app display name changed to "YourApp Terminal")
```

## Building the Android app

You need a real machine with internet access to Google's Android SDK
servers (this was built without that access, so it has NOT been
compiled/tested as an APK yet):

```bash
cd android/termux-apps
# Requires JDK 17+, Android SDK cmdline-tools (compileSdk 37, NDK 29 —
# check termux-app/build.gradle.kts for the exact versions).
./gradlew assembleDebug
adb install termux-app/build/outputs/apk/debug/app-debug.apk
```

The only Android-side change made so far is the app display name
(`termux-app/src/main/res/values/strings.xml` → `application_name`).
The package/applicationId (`com.termux`) was deliberately left unchanged —
Termux hardcodes this path (`/data/data/com.termux/files/usr`) in many
places, and a full rename is a known, invasive undertaking across the
whole codebase. Treat deeper rebranding (package name, icon, splash) as a
separate follow-up task, ideally done incrementally with a real build
available to verify nothing breaks at each step.

## Getting the script suite running inside Termux

Once you have the APK built and installed, inside the app run:

```bash
curl -fsSL <wherever you host install.sh> | bash
```

Or, without hosting it yet, just push this repo to the device and run
`bash install.sh` directly from inside Termux.

## Running on PC

Same installer, same script suite:

```bash
bash install.sh
source ~/.bashrc   # or open a new shell
yourapp config      # paste your OpenRouter (or other) API key
yourapp             # opens the menu
```

## What's been tested

- All scripts pass `bash -n` syntax checks
- `lib/common.sh` config read/write logic — tested end to end (see
  commit history / build notes) with real temp directories, confirmed
  correct JSON round-tripping and 600 file permissions
- `yourapp-chat` and `yourapp-models` response parsing — tested against
  mocked API responses, including adversarial input (embedded quotes,
  backslashes, triple-quote sequences) to confirm the safe temp-file-based
  parsing approach doesn't break, unlike naive string interpolation
- Full install flow — dry-run tested in an isolated fake $HOME, confirmed
  PATH wiring, config creation, and command dispatch all work correctly

## What's NOT been tested (needs a real environment)

- Actual OpenRouter API calls (no network access to openrouter.ai from the
  build environment) — the request/response shape should be correct per
  their documented API, but verify with a real key before shipping
- The actual Android APK build/compile (no Android SDK access — see above)
- OpenCode's exact environment variable / config schema for custom
  OpenAI-compatible endpoints — `yourapp-agent` makes a reasonable
  assumption (`OPENAI_API_KEY` / `OPENAI_BASE_URL`) but confirm against
  OpenCode's current docs (https://opencode.ai/docs) before relying on it
- Termux-specific behavior (pkg install paths, $PREFIX handling) — written
  per Termux's documented conventions but not run inside a real Termux
  instance
