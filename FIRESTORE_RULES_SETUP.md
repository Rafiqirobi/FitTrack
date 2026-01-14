# Firestore Security Rules Setup

## Problem
Your app is getting a `PERMISSION_DENIED` error when trying to read from the `workouts` collection. This is because Firebase Firestore has default restrictive rules that deny all access unless explicitly allowed.

## Solution
I've created a `firestore.rules` file in your project root that defines proper security rules for your app.

## How to Deploy

### Option 1: Using Firebase CLI (Recommended)
1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase in your project** (if not already done):
   ```bash
   cd c:\Users\USER\project\FitTrack\FitTrack-1
   firebase init
   ```

4. **Deploy the security rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Option 2: Using Firebase Console (Web UI)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your FitTrack project
3. Navigate to **Firestore Database**
4. Click the **Rules** tab
5. Copy the contents of `firestore.rules` file
6. Paste it into the Firebase Console Rules editor
7. Click **Publish**

## What These Rules Allow

✅ **Public Read Access** (No authentication required):
- Anyone can read from the `workouts` collection
- This is needed for browsing available workouts

✅ **User-Specific Access** (Authentication required):
- Users can only read/write their own data in:
  - `users/{userId}/completedWorkouts` - Track completed workouts
  - `users/{userId}/favorites` - User's favorite workouts
  - `users/{userId}/workouts` - User's personal workouts
  - `users/{userId}/runs` - GPS run routes
  - `users/{userId}/settings` - Goals and preferences

❌ **Blocked**:
- Clients cannot modify the public workouts catalog
- No access to other users' data
- All other unauthorized paths

## Testing in Your App
After deploying the rules, your app should:
1. ✅ Load the workouts catalog (Browse screen)
2. ✅ Save completed workouts (after workout timer)
3. ✅ Load user stats and history
4. ✅ Save favorite workouts
5. ✅ Save GPS runs

If you still get permission errors after deploying:
- Clear your app cache/data
- Restart the app
- Check that you're logged in (user-specific operations need authentication)

## Troubleshooting

**Error: "The caller does not have permission"**
- Make sure you've deployed the rules to Firestore
- Check that the collection path matches what's in the rules
- For user data, ensure you're authenticated

**Firestore not initialized**
- Verify Firebase project is set up correctly
- Check `google-services.json` exists in `android/app/src/`
- Ensure `Firebase.initializeApp()` is called in `main.dart`
