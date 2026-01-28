# ADR-004: Authentication Flow

**Status**: Accepted (Revised)
**Date**: 2026-01-27
**Decision Makers**: Sebastian (CEO/Product Owner), Backend Architecture Team

## Context

The diet tracking app requires secure authentication that:
- Prioritizes user privacy (health data is sensitive)
- Enables seamless iOS experience with Sign in with Apple
- Supports family sharing with appropriate access controls
- Works offline (sessions must persist locally)
- Integrates with our new MongoDB + bare metal architecture
- **CRITICAL: Costs $0 at 10K MAU**

The previous Supabase Auth approach was replaced due to the overall architecture change to MongoDB + Clerk.

## Decision

We will use **Clerk** for authentication with **Sign in with Apple** as the primary (and initially only) authentication method.

### Why Clerk?

1. **Free Tier**: 10,000 MAU included at $0 - perfect fit for budget
2. **Sign in with Apple**: First-class support, no additional configuration
3. **iOS SDK**: Native Swift SDK with SwiftUI components
4. **JWT Tokens**: Standard JWT for backend verification
5. **User Management**: Built-in user profiles, metadata storage

### Authentication Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS App (SwiftUI)                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Clerk iOS SDK                             ││
│  │  ┌─────────────────┐    ┌─────────────────────────────────┐ ││
│  │  │ Sign in with    │    │  Session Management             │ ││
│  │  │ Apple Button    │    │  - JWT storage (Keychain)       │ ││
│  │  │ (Native)        │    │  - Auto refresh                 │ ││
│  │  └─────────────────┘    │  - Offline persistence          │ ││
│  │                         └─────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  Local AuthManager                           ││
│  │  - Wraps Clerk SDK                                          ││
│  │  - Handles offline state                                    ││
│  │  - Provides auth state to app                               ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ HTTPS (JWT Bearer Token)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Backend API (Node.js/Express)                │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  Clerk JWT Middleware                        ││
│  │  - Verifies JWT signature using Clerk JWKS                  ││
│  │  - Extracts user ID (sub claim)                             ││
│  │  - Attaches user to request context                         ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                     MongoDB                                  ││
│  │  - users collection (linked by clerkId)                     ││
│  │  - Application data                                          ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ JWKS verification
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Clerk                                    │
├─────────────────────────────────────────────────────────────────┤
│  - User database                                                │
│  - Session management                                           │
│  - JWKS endpoint for JWT verification                           │
│  - Sign in with Apple OAuth flow                                │
└─────────────────────────────────────────────────────────────────┘
```

## Sign in with Apple Flow

### Step-by-Step Authentication

```
┌─────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ iOS App │     │  Apple   │     │  Clerk   │     │ Backend  │
└────┬────┘     └────┬─────┘     └────┬─────┘     └────┬─────┘
     │               │                │                │
     │ 1. User taps "Sign in with Apple"               │
     │────────────────>               │                │
     │               │                │                │
     │ 2. Apple presents native sign-in sheet          │
     │<────────────────               │                │
     │               │                │                │
     │ 3. User authenticates with Face ID/Touch ID     │
     │────────────────>               │                │
     │               │                │                │
     │ 4. Apple returns identity token + user info     │
     │<────────────────               │                │
     │               │                │                │
     │ 5. Clerk SDK sends Apple token to Clerk         │
     │───────────────────────────────>│                │
     │               │                │                │
     │               │   6. Clerk verifies with Apple  │
     │               │<───────────────│                │
     │               │                │                │
     │ 7. Clerk returns session + JWT                  │
     │<───────────────────────────────│                │
     │               │                │                │
     │ 8. Store session in Keychain   │                │
     │               │                │                │
     │ 9. API request with JWT        │                │
     │─────────────────────────────────────────────────>
     │               │                │                │
     │               │                │   10. Verify JWT
     │               │                │<───────────────│
     │               │                │                │
     │ 11. Response with user data    │                │
     │<─────────────────────────────────────────────────
     │               │                │                │
```

### Swift Implementation

```swift
import ClerkSDK
import SwiftUI

// MARK: - App Entry Point

@main
struct DietApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Auth Manager

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: ClerkUser?
    @Published var isLoading = false
    @Published var error: AuthError?

    private var clerk: Clerk { Clerk.shared }

    init() {
        // Check for existing session on launch
        Task {
            await restoreSession()
        }

        // Listen for auth state changes
        clerk.addChangeObserver { [weak self] in
            Task { @MainActor in
                self?.updateAuthState()
            }
        }
    }

    // MARK: - Sign in with Apple

    func signInWithApple() async {
        isLoading = true
        error = nil

        do {
            // Clerk handles the entire Apple OAuth flow
            try await clerk.signIn.create(strategy: .oauth(.apple))

            // Session is automatically created
            updateAuthState()

            // Create/update user in our MongoDB
            await syncUserToBackend()

        } catch let clerkError as ClerkAPIError {
            error = AuthError.clerkError(clerkError.message)
        } catch {
            error = AuthError.unknown(error.localizedDescription)
        }

        isLoading = false
    }

    // MARK: - Session Management

    func restoreSession() async {
        isLoading = true

        // Clerk automatically restores session from Keychain
        if let session = clerk.session {
            currentUser = session.user
            isAuthenticated = true

            // Verify session is still valid
            do {
                try await session.getToken()
            } catch {
                // Session expired, user needs to re-authenticate
                isAuthenticated = false
                currentUser = nil
            }
        }

        isLoading = false
    }

    func signOut() async {
        isLoading = true

        do {
            try await clerk.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            self.error = AuthError.signOutFailed
        }

        isLoading = false
    }

    private func updateAuthState() {
        isAuthenticated = clerk.session != nil
        currentUser = clerk.session?.user
    }

    // MARK: - Backend Sync

    private func syncUserToBackend() async {
        guard let token = try? await getAuthToken() else { return }

        // Call our API to create/update user document
        var request = URLRequest(url: URL(string: "\(Config.apiBaseURL)/users/me")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                print("Failed to sync user to backend")
                return
            }
        } catch {
            print("Error syncing user: \(error)")
        }
    }

    // MARK: - Token Management

    func getAuthToken() async throws -> String {
        guard let session = clerk.session else {
            throw AuthError.noSession
        }

        // Clerk handles token refresh automatically
        let token = try await session.getToken()
        return token
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case noSession
    case clerkError(String)
    case signOutFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No active session"
        case .clerkError(let message):
            return message
        case .signOutFailed:
            return "Failed to sign out"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 32) {
            // App logo and welcome text
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)

                Text("Diet Tracker")
                    .font(.largeTitle.bold())

                Text("Track your nutrition journey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Sign in with Apple button
            if authManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.email, .fullName]
                    },
                    onCompletion: { _ in
                        // Clerk handles this via its own flow
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, 32)
                .onTapGesture {
                    Task {
                        await authManager.signInWithApple()
                    }
                }

                // Note: The actual Clerk Sign in with Apple uses:
                // Button("Sign in with Apple") {
                //     Task { await authManager.signInWithApple() }
                // }
            }

            // Error display
            if let error = authManager.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Privacy note
            Text("Your data is stored securely and never shared without permission.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
```

## Backend JWT Verification

### Node.js/Express Middleware

```typescript
// middleware/auth.ts
import { ClerkExpressRequireAuth } from '@clerk/clerk-sdk-node';
import { Request, Response, NextFunction } from 'express';

// Option 1: Use Clerk's Express middleware (recommended)
export const requireAuth = ClerkExpressRequireAuth();

// Option 2: Manual JWT verification (for more control)
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

const client = jwksClient({
  jwksUri: `https://${process.env.CLERK_DOMAIN}/.well-known/jwks.json`,
  cache: true,
  rateLimit: true,
});

function getKey(header: jwt.JwtHeader, callback: jwt.SigningKeyCallback) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      callback(err);
      return;
    }
    const signingKey = key?.getPublicKey();
    callback(null, signingKey);
  });
}

export async function verifyClerkJWT(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization header' });
  }

  const token = authHeader.substring(7);

  jwt.verify(
    token,
    getKey,
    {
      algorithms: ['RS256'],
      issuer: `https://${process.env.CLERK_DOMAIN}`,
    },
    (err, decoded) => {
      if (err) {
        return res.status(401).json({ error: 'Invalid token' });
      }

      // Attach user info to request
      req.auth = {
        userId: decoded?.sub as string,
        sessionId: decoded?.sid as string,
      };

      next();
    }
  );
}

// types/express.d.ts
declare global {
  namespace Express {
    interface Request {
      auth?: {
        userId: string;
        sessionId: string;
      };
    }
  }
}
```

### User Sync Endpoint

```typescript
// routes/users.ts
import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import { User } from '../models/User';
import { clerkClient } from '@clerk/clerk-sdk-node';

const router = Router();

// Create or update user from Clerk
router.post('/users/me', requireAuth, async (req, res) => {
  try {
    const clerkUserId = req.auth!.userId;

    // Fetch full user data from Clerk
    const clerkUser = await clerkClient.users.getUser(clerkUserId);

    // Find or create user in our database
    const user = await User.findOneAndUpdate(
      { clerkId: clerkUserId },
      {
        $set: {
          email: clerkUser.emailAddresses[0]?.emailAddress,
          displayName: `${clerkUser.firstName || ''} ${clerkUser.lastName || ''}`.trim() || null,
          avatarUrl: clerkUser.imageUrl,
          updatedAt: new Date(),
        },
        $setOnInsert: {
          clerkId: clerkUserId,
          timezone: 'UTC',
          unitSystem: 'metric',
          language: 'en',
          subscriptionTier: 'free',
          shareWithFamily: false,
          aiProcessingConsent: true,
          analyticsConsent: true,
          createdAt: new Date(),
        },
      },
      { upsert: true, new: true }
    );

    res.status(user.createdAt === user.updatedAt ? 201 : 200).json({
      id: user._id,
      clerkId: user.clerkId,
      email: user.email,
      displayName: user.displayName,
    });
  } catch (error) {
    console.error('Error syncing user:', error);
    res.status(500).json({ error: 'Failed to sync user' });
  }
});

// Get current user
router.get('/users/me', requireAuth, async (req, res) => {
  try {
    const user = await User.findOne({ clerkId: req.auth!.userId });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

export default router;
```

## Offline Session Handling

### Session Persistence

Clerk automatically stores sessions in the iOS Keychain, but we add additional offline handling:

```swift
// OfflineAuthHandler.swift

class OfflineAuthHandler {
    private let clerk = Clerk.shared

    /// Check if we can operate offline with stored session
    func canOperateOffline() -> Bool {
        // Clerk stores session in Keychain
        // Even if expired, we allow offline operation with local data
        return clerk.session != nil
    }

    /// Get current session state
    func getSessionState() -> SessionState {
        guard let session = clerk.session else {
            return .unauthenticated
        }

        // Check if we have a cached token (Clerk caches tokens)
        if let tokenExpiration = session.lastActiveToken?.expiresAt,
           tokenExpiration > Date() {
            return .authenticated
        }

        return .expired(lastUserId: session.user?.id)
    }

    /// Handle app becoming online after offline period
    func handleNetworkRestore() async {
        guard let session = clerk.session else { return }

        do {
            // Clerk automatically refreshes expired tokens
            _ = try await session.getToken()

            // Trigger sync of offline changes
            await SyncManager.shared.syncPendingChanges()

        } catch {
            // Token refresh failed - user needs to re-authenticate
            NotificationCenter.default.post(
                name: .authReauthenticationRequired,
                object: nil
            )
        }
    }
}

enum SessionState {
    case authenticated
    case expired(lastUserId: String?)
    case unauthenticated
}
```

## Account Deletion

Apple requires apps to provide account deletion. Implementation:

```swift
// iOS Client
func deleteAccount() async throws {
    guard let token = try? await authManager.getAuthToken() else {
        throw AuthError.noSession
    }

    // 1. Call backend to delete all user data
    var request = URLRequest(url: URL(string: "\(Config.apiBaseURL)/users/me")!)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw AuthError.deletionFailed
    }

    // 2. Delete Clerk account
    try await Clerk.shared.user?.delete()

    // 3. Sign out locally
    await authManager.signOut()
}
```

```typescript
// Backend: routes/users.ts
router.delete('/users/me', requireAuth, async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const clerkUserId = req.auth!.userId;
    const user = await User.findOne({ clerkId: clerkUserId });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Delete all user data
    await FoodLog.deleteMany({ userId: user._id }, { session });
    await WeightLog.deleteMany({ userId: user._id }, { session });
    await UserGoal.deleteMany({ userId: user._id }, { session });
    await RecentFood.deleteMany({ userId: user._id }, { session });
    await DailySummary.deleteMany({ userId: user._id }, { session });
    await FamilyMember.deleteMany({ userId: user._id }, { session });

    // Handle families where user is owner
    const ownedFamilies = await Family.find({ createdByUserId: user._id });
    for (const family of ownedFamilies) {
      await FamilyMember.deleteMany({ familyId: family._id }, { session });
      await FamilyInvite.deleteMany({ familyId: family._id }, { session });
      await Family.findByIdAndDelete(family._id, { session });
    }

    // Delete user
    await User.findByIdAndDelete(user._id, { session });

    // Delete from Clerk (optional - user might do this themselves)
    try {
      await clerkClient.users.deleteUser(clerkUserId);
    } catch (clerkError) {
      console.log('Clerk user deletion handled by client');
    }

    await session.commitTransaction();

    res.json({ success: true, message: 'Account and all data deleted' });

  } catch (error) {
    await session.abortTransaction();
    console.error('Error deleting account:', error);
    res.status(500).json({ error: 'Failed to delete account' });
  } finally {
    session.endSession();
  }
});
```

## Security Considerations

### Token Storage

| Storage Method | Used For | Security |
|----------------|----------|----------|
| iOS Keychain (via Clerk SDK) | Session tokens | High - encrypted, secure enclave on supported devices |
| Never UserDefaults | N/A | Would be insecure |

### Apple Private Relay

When Sign in with Apple uses Private Relay, we receive a proxy email:
```
abc123xyz@privaterelay.appleid.com
```

Handling:
- Store and use as-is (Apple forwards emails)
- Don't display publicly in family sharing UI
- Allow user to optionally provide real email in settings

### JWT Validation Checklist

Backend must verify:
- [x] JWT signature (using Clerk's JWKS)
- [x] Token expiration (`exp` claim)
- [x] Issuer (`iss` matches Clerk domain)
- [x] Algorithm (`RS256` only)

## Consequences

### Positive

1. **Zero Cost**: Clerk free tier includes 10K MAU
2. **Privacy-First**: Sign in with Apple hides email, no password
3. **Seamless iOS**: Native experience with AuthenticationServices
4. **Secure Storage**: Clerk SDK handles Keychain storage
5. **Simple Integration**: Well-documented SDK for iOS and Node.js

### Negative

1. **Clerk Dependency**: Locked into Clerk for auth (mitigated: can migrate)
2. **Apple-Only Initially**: No web/Android until we add more providers
3. **Relay Email**: Proxy emails can complicate support

### Future Enhancements

1. **Google Sign-In**: For Android app when built
2. **Email Magic Link**: For web app
3. **Biometric Lock**: Additional security layer in app

## References

- [Clerk Documentation](https://clerk.com/docs)
- [Clerk iOS SDK](https://clerk.com/docs/quickstarts/ios)
- [Clerk Sign in with Apple](https://clerk.com/docs/authentication/social-connections/apple)
- [Clerk Node.js SDK](https://clerk.com/docs/references/nodejs/overview)
- [Sign in with Apple - Apple Developer](https://developer.apple.com/sign-in-with-apple/)
