# Pharma Intelligence — Android App (Flutter)

Flutter source for the Pharma Intelligence app. Builds into an APK distributed
directly from the website (no Google Play needed).

## API Endpoints (live in n8n)

| Purpose | Method | URL |
|---|---|---|
| Latest report | GET | `https://ashubaba02.app.n8n.cloud/webhook/pharma/latest-report` |
| Reports list (last 30) | GET | `https://ashubaba02.app.n8n.cloud/webhook/pharma/reports` |
| Subscribe | POST | `https://ashubaba02.app.n8n.cloud/webhook/pharma/subscribe` (JSON body: `{"email": "..."}`) |
| Mizo chatbot | POST | `https://ashubaba02.app.n8n.cloud/webhook/20d821d7-ec90-45c2-b9a4-ebe12bcc7df1/chat` (JSON body: `{"action":"sendMessage","sessionId":"...","chatInput":"..."}`) |

## Build the APK (Codemagic)

Pre-build script:

```bash
flutter create . --org com.pharmaintel --project-name pharma_intel
flutter pub get
Build: Flutter stable, Release mode, APK format.
Artifact: build/app/outputs/flutter-apk/app-release.apk

Screens
Today — latest pharma report
History — past reports
Subscribe — email signup
Mizo — chat with the Mizo assistant

Commit it, and your repo is complete. Now head back to Codemagic:

1. **Add application** → GitHub → select `pharma-intel-app`
2. Project type: **Flutter App**
3. Flutter version: **stable**, build mode: **Release**, format: **APK**
4. Pre-build script:
   ```bash
   flutter create . --org com.pharmaintel --project-name pharma_intel
   flutter pub get
