# Civic Reporter Developer Setup Guide — Live Authentication & API Keys

This guide provides step-by-step instructions for configuring production credentials for **Google OAuth 2.0**, **Live Mobile SMS Gateways (Firebase / Twilio / Fast2SMS)**, **Google Cloud Vision AI**, and **Email SMTP**.

---

## 1. Setting Up Live Google OAuth 2.0 Authentication

### Step 1: Firebase & Google Cloud Console Configuration
1. Go to the [Firebase Console](https://console.firebase.google.com/) and create or select your project (`civic-reporter-app`).
2. Navigate to **Project Settings** > **General** > **Your apps**.
3. Register your app platform:
   - **Web**: Add a Web App and copy `apiKey`, `authDomain`, `projectId`, and `appId`.
   - **Android**: Add an Android App (`org.civicreporter.app`) and input your SHA-1 fingerprint:
     ```bash
     keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
     ```
4. Navigate to **Authentication** > **Sign-in method** > **Google** and click **Enable**.
5. Go to [Google Cloud Console Credentials](https://console.cloud.google.com/apis/credentials) and copy your **OAuth 2.0 Client ID** and **Client Secret**.

### Step 2: Environment Declaration
Paste the keys into your [.env](file:///c:/projects/civic_reporter/.env) file:
```env
FIREBASE_API_KEY=AIzaSy...
FIREBASE_AUTH_DOMAIN=civic-reporter-app.firebaseapp.com
FIREBASE_PROJECT_ID=civic-reporter-app
GOOGLE_CLIENT_ID=1234567890-xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxx
```

---

## 2. Setting Up Live Mobile SMS OTP Authentication

### Option A: Firebase Phone Authentication (Default Live SDK)
1. In [Firebase Console](https://console.firebase.google.com/), go to **Authentication** > **Sign-in method**.
2. Click **Phone** and set to **Enable**.
3. Under **Testing Phone Numbers**, add any test numbers with static OTPs for automated end-to-end testing (e.g. `+91 9876543210` -> `123456`).

### Option B: Twilio SMS Gateway Integration
1. Sign up at [Twilio Console](https://www.twilio.com/console).
2. Copy your **Account SID** and **Auth Token** from the dashboard header.
3. Purchase or assign a verified Twilio SMS Phone Number.
4. Add to [.env](file:///c:/projects/civic_reporter/.env):
```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+18005550199
```

### Option C: Fast2SMS Gateway Integration (India Region)
1. Register at [Fast2SMS](https://www.fast2sms.com/).
2. Navigate to **Dev API** > **API Key**.
3. Copy your API key into [.env](file:///c:/projects/civic_reporter/.env):
```env
FAST2SMS_API_KEY=your_fast2sms_api_key
```

---

## 3. Setting Up Google Cloud Vision AI (Image Moderation)
1. Open [Google Cloud Console APIs & Services](https://console.cloud.google.com/apis/library).
2. Search for **Cloud Vision API** and click **Enable**.
3. Navigate to **Credentials** > **Create Credentials** > **API Key**.
4. Restrict the API key to the Cloud Vision API service.
5. Add to [.env](file:///c:/projects/civic_reporter/.env):
```env
VISION_API_KEY=AIzaSy...
```

---

## 4. Setting Up SMTP Email Notifications
1. Obtain SMTP host credentials from your mail service (SendGrid, Mailgun, or Gmail App Password).
2. Add to [.env](file:///c:/projects/civic_reporter/.env):
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=notifications@civicreporter.org
SMTP_PASS=your_app_password
```

---

## 5. Verification Command
To verify runtime configuration:
```bash
flutter run
```
The app log will print:
`=== Civic Reporter Production Environment Status ===`
