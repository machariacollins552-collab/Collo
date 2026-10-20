# Collins Fit AI

An elegant Android fitness and weight-loss app with a real AI coach (**FitCoach AI**),
affordable Kenyan meal plans, gentle home workouts, weight tracking and daily habits.
Built with Flutter. Your tracking data stays on your phone.

> **Honest status.** The backend has automated tests that pass (19 of 19).
> The Flutter app was written and reviewed by hand, but it has **not been compiled, run
> on a phone, or connected to a live AI yet**. Your first GitHub build is the first real
> compile. If it fails, the log shows exactly which file and line; send that to Claude
> and it will be fixed.

---

## What is inside

| Part | What it does |
| --- | --- |
| `lib/` | The Flutter app (Dart): splash, onboarding, home, coach chat, meals, workouts, progress, habits, profile |
| `android/` | Android build settings (Gradle 9.3.1, Android Gradle Plugin 9.1.0, Kotlin 2.4.0, Java 17, matched to Flutter 3.47) |
| `backend/` | A tiny server (Cloudflare Worker) that holds your Gemini key and talks to the AI |
| `test/` | Automated tests for the app logic, chat networking, storage and the first-run flow |
| `.github/workflows/build-apk.yml` | Builds the APK in the cloud, so you need no computer |

**The AI key is never in the app.** The app sends your question to *your* server, and the
server adds the secret key and asks Google Gemini. If the server is down, offline, or out of
free quota, the app tells you. It never makes up an answer.

## What it costs

| Item | Cost |
| --- | --- |
| Flutter, GitHub account, public repository | Free |
| GitHub Actions for a private repository | Free monthly allowance (check github.com/pricing for today's number). A build takes roughly 5 to 15 minutes |
| Cloudflare Workers (the backend) | The Free plan allows 100,000 requests a day. Cloudflare may ask for an account but this app does not need a paid plan |
| Google Gemini API | Free tier through Google AI Studio. Limits are set by Google and can change. You must be 18 or older |
| Google Play Store | **Not used.** You install the APK directly. Publishing on Play would cost a one-time developer fee |

**Privacy note about the free Gemini tier.** Google's terms say content sent through the
free (unpaid) tier may be used to improve Google's products and may be read by human
reviewers. Do not type phone numbers, medical records or other private details into the
chat. The app also lets you turn off sharing your weight and preferences with the coach
(Profile, Privacy).

---

## Set up from an Android phone

You do four things: (1) get the AI server running, (2) put the project on GitHub,
(3) build the APK, (4) install it. Use Chrome. For GitHub pages that look cramped,
open Chrome's menu and tick **Desktop site**.

### Part 1. Get a free Gemini key

1. Open **aistudio.google.com/apikey** and sign in with a Google account.
2. Tap **Create API key** and copy it. Treat it like a password.
   Do not paste it into GitHub, into the app, or into any chat.

### Part 2. Put the AI server online (Cloudflare Workers)

1. Create a free account at **dash.cloudflare.com**.
2. Open **Workers & Pages**, then **Create** (or **Create application**), then start from
   the **Hello World** template, give it the name `collins-fit-ai-coach`, and **Deploy**.
3. Tap **Edit code**. Delete the sample code. Open `backend/src/index.js` from this project,
   copy the whole file, paste it in the editor, and **Deploy**.
4. Open the Worker's **Settings**, then **Variables and Secrets**, and add a
   **Secret** named `GEMINI_API_KEY` with the key from Part 1. Deploy again if asked.
5. Open `https://YOUR-WORKER-ADDRESS/health` in Chrome. You should see
   `"ok":true` and `"configured":true`. If `configured` is `false`, the secret is missing
   or misspelled.

Cloudflare renames menu items now and then. If a name differs, look for the closest match.
Your Worker address looks like `https://collins-fit-ai-coach.YOUR-NAME.workers.dev`.
Write it down. It is an address, not a secret.

Optional: add a plain variable `GEMINI_MODEL` to switch AI models without touching code.
The default is `gemini-3.8-flash`. If chat says the free limit is reached on your very
first message, set `GEMINI_MODEL` to `gemini-3.5-flash-lite` and try again.

### Part 3. Put the project on GitHub

GitHub's phone upload cannot keep folders, so the project comes as **one zip file**
and a small workflow unpacks it for you.

1. On **github.com**, tap **+**, then **New repository**. Name it `collins-fit-ai`.
   Choose **Private** (recommended), leave everything else empty, and **Create repository**.
2. On the empty repository page tap **uploading an existing file**. Choose
   `collins-fit-ai-source.zip` and tap **Commit changes**. The file name must stay exactly
   `collins-fit-ai-source.zip`.
3. Tap **Add file**, then **Create new file**. As the name type
   `.github/workflows/unpack.yml` (typing `/` makes folders). Paste the unpack workflow
   (given to you with the zip, also saved as `workflow-to-add/unpack.yml`
   after unpacking), then **Commit changes**.
4. Open the **Actions** tab, choose **Unpack project zip**, tap **Run workflow**, and wait
   for the green tick. Your project files are now in the repository.
5. One last file must be added by hand, because GitHub does not let automation create
   workflow files. Open `workflow-to-add/build-apk.yml` in the repository, tap **Raw**,
   select all and copy. Tap **Add file**, **Create new file**, name it
   `.github/workflows/build-apk.yml`, paste, and **Commit changes**.
   This commit starts your first build automatically.

### Part 4. Build, download and install the APK

1. Open the **Actions** tab and tap the **Build Android APK** run. It takes roughly
   5 to 15 minutes. A green tick means it worked.
   A red cross means a step failed: open it and read the red lines.
2. Download the APK. The easy way: open the repository's **Releases** page, tap
   **Collins Fit AI - latest build**, and tap **collins-fit-ai.apk**.
   (Or open the run and download the **collins-fit-ai-apk** artifact. That one arrives
   inside a `.zip`, which you open with the Samsung **My Files** app.)
3. Open the downloaded file. Android asks permission for Chrome to **install unknown
   apps**: allow it for this one install. If Google Play Protect warns about an unknown
   developer, tap **Install anyway**. That warning appears for every app that does not come
   from the Play Store. If your phone has **Auto Blocker** turned on, switch it off
   for the install.
4. Open **Collins Fit AI**, complete the short setup, and you are in.

### Part 5. Connect and test the AI coach

1. In the app open **Profile**, then **AI connection**.
2. Paste your Worker address and tap **Test connection**. You want to see
   "Connected. FitCoach AI is ready." Then tap **Save**.
3. Open **Coach** and tap **Plan my meals today.** A real answer should appear in a few
   seconds. Try asking something unusual, such as a cheap vegetarian dinner using
   cabbage and eggs. A real model gives a different, fitting answer each time.

Prefer not to paste the address in the app? In GitHub open **Settings, Secrets and
variables, Actions, Variables**, add a repository variable named `BACKEND_URL` with your
Worker address, and run the build again. The address is then built into the APK.

---

## Debug key vs your own signing key

Every Android app must be digitally signed. Two kinds matter here:

* **Debug signing (what you get by default).** Fine for installing on your own phone.
  It cannot be uploaded to the Play Store. To stop Android refusing updates, the workflow
  keeps the same debug key between builds using GitHub's cache. GitHub deletes caches that
  go unused for about a week. If that happens the next build has a different key, Android
  says **App not installed**, and you must uninstall the old app first (your local data
  in the old app is lost).
* **Release signing with your own key.** A permanent key that you own. Needed for the
  Play Store, and it makes updates install smoothly for good. Creating the key needs
  `keytool`, which is easiest on a computer, in GitHub Codespaces or in Termux:

  ```
  keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  base64 -w0 upload-keystore.jks
  ```

  Then add four repository **secrets** (Settings, Secrets and variables, Actions):
  `KEYSTORE_BASE64` (the long base64 text), `KEYSTORE_PASSWORD`, `KEY_ALIAS` (`upload`) and
  `KEY_PASSWORD`. The workflow detects them and signs with your key. **Back the key up.**
  If you lose it you can never update the app under the same identity. Never commit it to
  GitHub.

---

## Troubleshooting

| What you see | What to do |
| --- | --- |
| Build fails on **Analyze the code** | Open the step, copy the red error lines, send them to Claude |
| Build fails on **Run the tests** | Same: copy the failing test name and message |
| **App not installed** | Uninstall the old Collins Fit AI, then install the new APK |
| "AI server not connected yet" | Profile, AI connection, paste your Worker address |
| "Reached a server, but it is not the FitCoach backend" | The address is wrong. It should be the Worker's `workers.dev` address with no `/chat` on the end |
| "its AI key is not set yet" | Add the `GEMINI_API_KEY` secret in Cloudflare |
| "The AI service rejected the server credentials" | The Gemini key is wrong or was deleted. Make a new one and update the secret |
| "Reached its free usage limit" | You hit Google's free quota or this server's limits. Wait, or set `GEMINI_MODEL` as described in Part 2 |
| "Offline" or "can't be reached" | Check mobile data or Wi-Fi. Tracking still works offline; live chat needs internet |

## Safety design

* FitCoach is told it is not a doctor, never to diagnose, and to point medical questions
  to qualified care. It must refuse starvation, extreme fasting, purging, laxatives, detox
  teas and unprescribed weight-loss drugs, and it is limited to gradual loss.
* Onboarding and settings reject very large weight goals. Progress messages are gentle and
  never shame a rise.
* The app and server limit message length and how fast messages can be sent. The server
  validates every request, uses timeouts, and never writes chat text to its logs.

Limits you should know about: the server's rate limiter is best effort (it lives in the
memory of each Worker instance), and anyone who learns your Worker address could spend
your free quota. For a little extra protection, add a secret named `APP_TOKEN` in
Cloudflare and a repository secret with the same name and value in GitHub, then rebuild.
The app then sends that token with every request and the server rejects requests without
it. Remember that anything inside an APK can be extracted, so a token only deters casual
misuse. Data on the phone is stored in the app's private storage but is not separately
encrypted.

## For developers

```
lib/
  core/      theme, config, number and date helpers
  data/      local storage, Kenyan meal database, workouts, insights
  models/    profile, weights, habits, chat, saved plans
  services/  CoachService: the only code that talks to the network
  state/     AppState (ChangeNotifier) and AppScope
  screens/   one file per screen
  widgets/   shared components, charts, inputs
backend/     Cloudflare Worker: /chat and /health, tests with `npm test`
```

* Flutter 3.47, Dart 3.5 or newer, Java 17. Dependencies: `http` and `shared_preferences` only.
* Backend tests: `cd backend && npm test` (Node 20 or newer).
* Run the app tests: `flutter test`. Analyze: `flutter analyze`.
* Build locally: `flutter build apk --release --dart-define=BACKEND_URL=https://your-worker.workers.dev`

Collins Fit AI offers general wellbeing information. It is not medical advice and does
not replace a doctor, nurse or dietitian.
