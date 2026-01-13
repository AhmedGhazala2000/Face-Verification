# System Architecture - Cloud Face Recognition

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         REGISTRATION FLOW                            │
└─────────────────────────────────────────────────────────────────────┘

    User Device                    Firebase Cloud
    ───────────                    ──────────────
         │
         │  1. Capture Face
         ├──────────────────►
         │                         Camera Image
         │
         │  2. Extract Embedding
         ├──────────────────►
         │                    [512 float values]
         │
         │  3. Save to Firestore
         ├─────────────────────────────────►  users/{userId}
         │                                     {name, email, faceId}
         │
         │  4. Save Embedding
         ├─────────────────────────────────►  face_embeddings/{faceId}
         │                                     {embedding: [0.1, -0.2, ...]}
         │
         │  5. Save Local Backup
         ├──────────────────►
         │                    SQLite Database
         │                    (offline access)
         │


┌─────────────────────────────────────────────────────────────────────┐
│                           LOGIN FLOW                                 │
└─────────────────────────────────────────────────────────────────────┘

    User Device                    Firebase Cloud
    ───────────                    ──────────────
         │
         │  1. Capture Face
         ├──────────────────►
         │                         Camera Image
         │
         │  2. Extract Embedding
         ├──────────────────►
         │                    [512 float values]
         │
         │  3. Fetch All Embeddings
         ├─────────────────────────────────►  Read from
         │◄────────────────────────────────   face_embeddings/*
         │                                     Collection
         │
         │  4. Compare Embeddings
         │  ┌──────────────────┐
         │  │ Cosine Similarity│
         │  │   For Each User  │
         │  │                  │
         │  │ Best Match >= 0.85? ────► YES ──► LOGIN SUCCESS
         │  │                  │
         │  └──────────────────┘         NO
         │           │                    │
         │           │                    ▼
         │           │          5. Try Local Verification
         │           │          ┌────────────────┐
         │           │          │  FaceSDK Match │
         │           │          │  From Local DB │
         │           │          └────────────────┘
         │           │                    │
         │           │                    ├──► SUCCESS
         │           │                    └──► FAIL
         │
         │  6. Get User Details
         ├─────────────────────────────────►  Read from
         │◄────────────────────────────────   users/{userId}
         │                                     
         │
         │  7. Show Welcome Screen
         │


┌─────────────────────────────────────────────────────────────────────┐
│                      EMBEDDING COMPARISON                            │
└─────────────────────────────────────────────────────────────────────┘

Captured Face Embedding:        [0.12, -0.45, 0.78, ..., 0.34]
                                             │
                                             ▼
                                 ┌────────────────────┐
                                 │ Cosine Similarity  │
                                 │                    │
                                 │    A · B           │
                                 │ ─────────────      │
                                 │  ||A|| × ||B||     │
                                 └────────────────────┘
                                             │
                ┌────────────────────────────┼────────────────────────┐
                ▼                            ▼                        ▼
         Stored User 1             Stored User 2              Stored User 3
    [0.11, -0.44, 0.79, ...]  [0.56, 0.23, -0.12, ...]  [0.13, -0.46, 0.77, ...]
                │                            │                        │
                ▼                            ▼                        ▼
         Similarity: 0.96            Similarity: 0.23           Similarity: 0.94
              │                            │                          │
              ▼                            ▼                          ▼
          ✅ MATCH!                    ❌ NO MATCH              🤔 Close, but
        (threshold: 0.85)           (too different)          threshold not met


┌─────────────────────────────────────────────────────────────────────┐
│                    CROSS-DEVICE SCENARIO                             │
└─────────────────────────────────────────────────────────────────────┘

    Device A (Phone)                   Firebase Cloud                Device B (Tablet)
    ────────────────                   ──────────────                ─────────────────
         │
         │  Register User
         │  ┌─────────────┐
         │  │ Capture Face│
         │  │ Enter Name  │
         │  │ Enter Email │
         │  └─────────────┘
         │        │
         │        ▼
         │  Save to Firestore ───────────────►  ☁️  Cloud Storage
         │                                         │
         │                                         │ Data synced
         │                                         │ automatically
         │                                         │
         │                                         ▼
         │                                    [User Data]
         │                                    [Embedding]
         │                                         │
         │                                         │
         │                    Later...              │
         │                                         │
         │                                         │◄──── Fetch Data
         │                                         │
         │                                         ▼
         │                                    Device B Login
         │                                    ┌─────────────┐
         │                                    │ Capture Face│
         │                                    │ Compare     │
         │                                    │ ✅ MATCH!   │
         │                                    └─────────────┘
         │
    User can login from ANY device with internet connection!


┌─────────────────────────────────────────────────────────────────────┐
│                      OFFLINE MODE                                    │
└─────────────────────────────────────────────────────────────────────┘

    Registration (Online)              Login (Offline)
    ────────────────────              ─────────────
         │                                    │
         ▼                                    ▼
    ☁️  Firestore                         ❌ No Internet
         │                                    │
         │ Sync                               │
         ▼                                    ▼
    📱 Local SQLite ◄────────────────► 📱 Local SQLite
         │                                    │
         │                                    │ Use local data
         │                                    ▼
         │                              FaceSDK Verify
         │                                    │
         │                                    ▼
         │                              ✅ Login Success
         │                              (using local embeddings)


┌─────────────────────────────────────────────────────────────────────┐
│                    FIREBASE COLLECTIONS                              │
└─────────────────────────────────────────────────────────────────────┘

Firestore Database
├── users/
│   ├── uid_1234567890
│   │   ├── name: "John Doe"
│   │   ├── email: "john@example.com"
│   │   ├── faceId: "user_1234567890"
│   │   ├── createdAt: Timestamp
│   │   └── updatedAt: Timestamp
│   │
│   ├── uid_9876543210
│   │   ├── name: "Jane Smith"
│   │   ├── email: "jane@example.com"
│   │   └── ...
│   │
│   └── ...
│
└── face_embeddings/
    ├── user_1234567890
    │   ├── userId: "uid_1234567890"
    │   ├── embedding: [0.12, -0.45, 0.78, ..., 0.34]  (512 floats)
    │   └── createdAt: Timestamp
    │
    ├── user_9876543210
    │   ├── userId: "uid_9876543210"
    │   ├── embedding: [0.56, 0.23, -0.12, ..., 0.89]  (512 floats)
    │   └── createdAt: Timestamp
    │
    └── ...


┌─────────────────────────────────────────────────────────────────────┐
│                  ERROR HANDLING FLOW                                 │
└─────────────────────────────────────────────────────────────────────┘

    Login Attempt
         │
         ▼
    ┌─────────────────┐
    │ Try Cloud Match │
    └─────────────────┘
         │
         ├──► Success? ──YES──► Login ✅
         │
         NO
         │
         ▼
    ┌─────────────────┐
    │ Try Local Match │
    └─────────────────┘
         │
         ├──► Success? ──YES──► Login ✅
         │
         NO
         │
         ▼
    Show Error Message
    "Face not recognized"
         │
         ▼
    User Can:
    ├──► Try Again
    ├──► Register New Account
    └──► Contact Support


┌─────────────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                                   │
└─────────────────────────────────────────────────────────────────────┘

    Development (Current):
    ─────────────────────
    ┌────────────────────────────┐
    │ Firestore Rules: Allow All │  ⚠️ Not Secure
    └────────────────────────────┘
             │
             ▼
    Anyone can read/write


    Production (Recommended):
    ────────────────────────
    ┌──────────────────────────────┐
    │ Firebase Authentication      │
    │ (Email/Password, Google, etc)│
    └──────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │ Firestore Security Rules     │
    │ - Authenticated users only   │
    │ - Rate limiting              │
    │ - Field validation           │
    └──────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │ App Check                    │
    │ - Verify genuine app         │
    │ - Block unauthorized access  │
    └──────────────────────────────┘
```

## 🎯 Key Takeaways

1. **Registration**: Captures face → Extracts embedding → Saves to cloud + local
2. **Login**: Captures face → Compares with cloud embeddings → Matches using cosine similarity
3. **Cross-Device**: All data in cloud → Any device can access → Seamless login experience
4. **Offline Support**: Local database fallback → Works without internet
5. **Error Handling**: Multiple verification methods → Graceful degradation

## 📈 Performance Metrics

- **Embedding Size**: 512 floats × 4 bytes = 2KB per face
- **Comparison Speed**: ~0.1ms per embedding comparison
- **Network Usage**: ~2KB upload per registration, ~2KB download per login
- **Match Accuracy**: 85%+ similarity threshold (adjustable)

## 🔐 Security Considerations

**Development Mode** (Current):

- ✅ Fast setup
- ✅ Easy testing
- ❌ No access control
- ❌ No authentication

**Production Mode** (Recommended):

- ✅ User authentication
- ✅ Access control rules
- ✅ Rate limiting
- ✅ Audit logging

