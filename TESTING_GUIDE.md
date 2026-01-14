# Testing Guide - Face Image Display & UI Optimization

## 🧪 Complete Testing Checklist

### Test 1: New User Registration with Face Image

**Steps:**

1. Open the app
2. Tap "Register New User"
3. Position face in camera circle
4. Tap "Capture Face" button
5. Fill in Name and Email in dialog
6. Tap "Register"

**Expected Results:**

- ✅ Face captured successfully message
- ✅ Image saved to: `{AppDocs}/face_images/{faceId}.jpg`
- ✅ User saved to Firestore with imagePath
- ✅ Registration success snackbar appears
- ✅ Returns to home screen

**Verification:**

```dart
// Check storage location
print
(
await StorageService.instance.getFaceImagePath(faceId));
// Should return path if exists
```

---

### Test 2: Login with Face Recognition

**Steps:**

1. From home screen, tap "Login with Face"
2. Position face in camera
3. Tap "Verify Face" button
4. Wait for recognition

**Expected Results:**

- ✅ Face recognized successfully
- ✅ Success dialog shows user name and email
- ✅ Tap "Continue" to proceed
- ✅ Returns to home with logged-in view

**Verification:**

- User's actual face photo should be visible in profile avatar
- If image exists, it displays in circular frame
- Verified badge shown on avatar

---

### Test 3: Profile Display with Face Image

**Steps:**

1. After successful login
2. Observe home screen

**Expected Results:**

- ✅ **User's face photo displayed** in 160x160 circle
- ✅ Purple gradient border around avatar
- ✅ Green verified badge at bottom-right
- ✅ Welcome message with emoji badge
- ✅ User name in large bold text (36px)
- ✅ Profile Details card showing:
    - Email address
    - Face ID
    - Member Since date
- ✅ Two status cards side-by-side:
    - Verified (green)
    - Cloud Synced (blue)
- ✅ Logout button at bottom

**Visual Checks:**

```
✓ Avatar is circular and centered
✓ Face image fills entire circle (cover fit)
✓ No distortion or stretching
✓ Purple gradient visible around edges
✓ Verified badge overlays on avatar
✓ All text is clearly readable
✓ Cards have proper shadows
✓ Colors match theme
```

---

### Test 4: Face Image Fallback

**Steps:**

1. Manually delete face image file (or use old user without image)
2. Login or display profile

**Expected Results:**

- ✅ Shows default person icon in green gradient
- ✅ No errors or crashes
- ✅ Rest of profile displays normally
- ✅ Verified badge still visible

**Code to Test:**

```dart
// Temporarily return null for testing
if (_loggedInUser!.imagePath != null &&
File(_loggedInUser!.imagePath!).existsSync())
```

---

### Test 5: Logout and Re-login

**Steps:**

1. From logged-in home screen
2. Tap "Logout" button
3. Confirm in dialog
4. Tap "Login with Face" again
5. Complete face verification

**Expected Results:**

- ✅ Logout confirmation dialog appears
- ✅ Returns to auth screen after logout
- ✅ Can successfully login again
- ✅ Face image persists and displays again
- ✅ All data intact

---

### Test 6: Multiple Users

**Steps:**

1. Register User A with face
2. Logout
3. Register User B with face
4. Login as User A
5. Logout
6. Login as User B

**Expected Results:**

- ✅ Each user has their own face image
- ✅ Correct image displays for logged-in user
- ✅ No mixing of user images
- ✅ All images stored separately

**File Check:**

```
{AppDocs}/face_images/
  ├─ user_1234567890.jpg  (User A)
  └─ user_0987654321.jpg  (User B)
```

---

### Test 7: UI Responsiveness

**Steps:**

1. Test on different screen sizes
2. Rotate device (if supported)
3. Scroll profile screen

**Expected Results:**

- ✅ Avatar maintains circular shape
- ✅ Cards adapt to width
- ✅ Text wraps properly
- ✅ Buttons remain full-width
- ✅ No overflow errors
- ✅ Smooth scrolling

---

### Test 8: Network Sync (Firestore)

**Steps:**

1. Enable airplane mode
2. Register new user
3. Disable airplane mode
4. Wait for sync

**Expected Results:**

- ✅ Registration works offline
- ✅ Data syncs when online
- ✅ Image path saved to Firestore
- ✅ Can login from another device (face verification needed)

**Firestore Check:**

```json
{
  "users": {
    "uid_xxx": {
      "name": "John Doe",
      "email": "john@example.com",
      "faceId": "user_1234567890",
      "imagePath": "/data/user/0/.../face_images/user_1234567890.jpg",
      "createdAt": "2026-01-14T...",
      "updatedAt": "2026-01-14T..."
    }
  }
}
```

---

### Test 9: Performance

**Steps:**

1. Register 10 users
2. Login as each user
3. Monitor app performance

**Expected Results:**

- ✅ No lag when loading images
- ✅ Smooth transitions
- ✅ Memory usage reasonable
- ✅ No memory leaks
- ✅ Fast face recognition

**Performance Metrics:**

- Image load time: < 100ms
- Screen transition: < 300ms
- Face verification: < 2 seconds

---

### Test 10: Error Handling

**Test Cases:**

**A. Corrupted Image File**

```dart
// Corrupt the image file
File
(
imagePath
)
.
writeAsString
(
'
corrupted
'
);
```

- ✅ Should fallback to icon
- ✅ No crash

**B. Missing Storage Permission**

- ✅ Handles gracefully
- ✅ Shows error message

**C. Firestore Offline**

- ✅ Works with local data
- ✅ Syncs when back online

**D. Camera Permission Denied**

- ✅ Shows permission message
- ✅ Cannot proceed without permission

---

## 🎯 Visual Validation Checklist

### Home Screen (Logged In)

```
┌────────────────────────────────────┐
│  Face Recognition        [Logout]  │ ✓ Header
│                                    │
│                                    │
│         ┌──────────┐               │
│         │          │               │ ✓ Avatar with
│         │  [FACE]  │🔰            │   face image
│         │          │               │   and badge
│         └──────────┘               │
│                                    │
│      👋 Welcome back!              │ ✓ Badge
│                                    │
│         John Doe                   │ ✓ Large name
│                                    │
│  ┌──────────────────────────────┐ │
│  │ 📋 Profile Details           │ │ ✓ Details card
│  │                              │ │
│  │ 📧 Email                     │ │
│  │    john@example.com          │ │
│  │ ─────────────────            │ │
│  │ 🔑 Face ID                   │ │
│  │    user_1234567890           │ │
│  │ ─────────────────            │ │
│  │ 📅 Member Since              │ │
│  │    Jan 14, 2026 at 10:30     │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────┐  ┌──────────┐      │
│  │    🔒    │  │    ☁️    │      │ ✓ Status cards
│  │ Verified │  │  Cloud   │      │   side-by-side
│  └──────────┘  └──────────┘      │
│                                    │
│  ┌──────────────────────────────┐ │
│  │        🚪 Logout             │ │ ✓ Logout button
│  └──────────────────────────────┘ │
└────────────────────────────────────┘
```

### Color Verification

- Background: Purple gradient (top to bottom)
- Avatar border: Purple gradient
- Verified badge: Green (#4CAF50)
- Cloud badge: Blue (#2196F3)
- Text: White with varying opacity
- Logout button: Red accent outline

---

## 🐛 Known Issues to Watch For

1. **Image Rotation**: Some cameras may rotate images
    - Check if face appears upright

2. **Large Images**: High-res cameras may create large files
    - Monitor storage usage

3. **Multiple Faces**: Should reject if multiple faces detected
    - Verify error message

4. **Poor Lighting**: May affect face detection
    - Test in various lighting conditions

---

## ✅ Success Criteria

All tests should pass with:

- ✅ Zero crashes
- ✅ Zero memory leaks
- ✅ Proper error handling
- ✅ Fast performance
- ✅ Smooth animations
- ✅ Correct data persistence
- ✅ Beautiful UI rendering
- ✅ Face images displayed correctly
- ✅ Proper fallbacks working

---

## 📊 Test Results Template

```
Test Date: ______________
Device: ______________
OS Version: ______________

Test 1: New User Registration      [ ] Pass [ ] Fail
Test 2: Login with Face            [ ] Pass [ ] Fail
Test 3: Profile Display            [ ] Pass [ ] Fail
Test 4: Face Image Fallback        [ ] Pass [ ] Fail
Test 5: Logout and Re-login        [ ] Pass [ ] Fail
Test 6: Multiple Users             [ ] Pass [ ] Fail
Test 7: UI Responsiveness          [ ] Pass [ ] Fail
Test 8: Network Sync               [ ] Pass [ ] Fail
Test 9: Performance                [ ] Pass [ ] Fail
Test 10: Error Handling            [ ] Pass [ ] Fail

Overall Result: [ ] PASS [ ] FAIL

Notes:
_________________________________
_________________________________
_________________________________
```

---

## 🚀 Quick Start Testing

**Fastest way to verify changes:**

1. Clean install app
2. Register a new user with your face
3. Complete registration
4. Verify your face image appears in profile
5. Logout
6. Login again
7. Verify your face image persists

**Expected time:** 2-3 minutes

---

## 📞 Support

If you encounter any issues:

1. Check console logs for errors
2. Verify file permissions
3. Confirm Firestore rules allow read/write
4. Ensure camera permissions granted
5. Check storage availability

