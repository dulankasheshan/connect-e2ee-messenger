# Connect Chat App — Flutter Frontend Documentation

A production-ready, real-time messaging application built with **Flutter**. This application strictly follows a **Feature-First Clean Architecture** and implements **End-to-End Encryption (E2EE)** to ensure maximum security and scalability.

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Tech Stack](#tech-stack)
3. [Folder Structure](#folder-structure)
4. [Domain Layer Specification](#domain-layer-specification)
5. [End-to-End Encryption (E2EE) Flow](#end-to-end-encryption-e2ee-flow)
6. [State Management & Routing](#state-management--routing)
7. [Security Guidelines](#security-guidelines)

---

## Architecture Overview

The application utilizes a **Feature-First Clean Architecture**. Instead of grouping files by layer (e.g., all domains together, all presentations together), the app is divided into distinct **Features**. Each feature contains its own isolated Clean Architecture layers:

1. **Domain Layer:** The innermost layer. Contains Entities, Repository Interfaces, and Use Cases. Pure Dart, no Flutter dependencies.
2. **Data Layer:** Implements the Domain repositories. Contains Models, Data Sources (Remote/Local), and API integration.
3. **Presentation Layer:** Contains UI components (Pages/Widgets) and State Management (BLoC/Riverpod).

---

## Tech Stack

| Category | Technology / Package   | Purpose |
| :--- |:-----------------------| :--- |
| **Framework** | Flutter (Dart)         | Cross-platform UI toolkit |
| **State Management** | flutter_bloc           | Predictable state container |
| **Networking** | dio                    | Robust HTTP client with interceptors |
| **Real-time** | socket_io_client       | WebSocket communication |
| **Cryptography** | pointycastle / encrypt | RSA/ECC key generation & encryption |
| **Secure Storage** | flutter_secure_storage | Securely storing tokens & Private Key |
| **Routing** | go_router              | Declarative routing |
| **Dependency Injection**| get_it & injectable    | Service locator and DI |

---

## Folder Structure

```text
lib/
├── core/                           # Shared utilities and configurations
│   ├── crypto/                     # E2EE helpers, key generation, encryption
│   ├── network/                    # Dio client, SocketManager, Interceptors
│   ├── storage/                    # Secure storage handler
│   ├── theme/                      # App colors, typography, theme data
│   └── utils/                      # Date formatters, validators
│
├── features/                       # Feature-based modules
│   ├── auth/                       # Authentication & Session
│   ├── profile/                    # User profile setup and management
│   ├── discover/                   # User search and blocking
│   ├── chat/                       # Real-time messaging & history
│   └── settings/                   # App preferences and privacy
│
└── main.dart                       # Entry point & App shell
```

## Domain Layer Specification

Below is the strict Domain Layer contract for each feature. No UI or external data dependencies should leak into these files.

### 1. `auth` Feature
Manages user authentication, token verification, and sessions.
* **Entities:** `AuthSession` (accessToken, refreshToken, isProfileComplete)
* **Repository Interface:** `IAuthRepository`
* **Use Cases:**
  * `SendOtpUseCase`
  * `VerifyOtpUseCase`
  * `RefreshTokenUseCase`
  * `LogoutUseCase`

### 2. `profile` Feature
Handles account initialization and profile updates.
* **Entities:** `UserProfile` (id, email, username, name, profilePicUrl, publicKey, fcmDeviceToken)
* **Repository Interface:** `IProfileRepository`
* **Use Cases:**
  * `SetupProfileUseCase` *(Generates E2EE keypair, saves private key locally, uploads public key)*
  * `GetMyProfileUseCase`
  * `UpdateProfileUseCase`

### 3. `discover` Feature
Handles finding new users and managing the blocklist.
* **Entities:** `SearchUser` (id, username, name, profilePicUrl, isOnline, lastSeen)
* **Repository Interface:** `IDiscoverRepository`
* **Use Cases:**
  * `SearchUsersUseCase`
  * `GetPublicKeyUseCase` *(Fetches a recipient's public key for encryption)*
  * `BlockUserUseCase` / `UnblockUserUseCase`

### 4. `chat` Feature
The core messaging engine handling REST history, offline sync, and real-time Socket events.
* **Entities:** * `Message` (id, senderId, receiverId, decryptedText, mediaUrl, status, createdAt)
  * `ChatEvent` (Typing, OnlineStatus, ReadReceipt)
* **Repository Interfaces:** `IChatRepository`, `IMediaRepository`
* **Use Cases:**
  * `SendMessageUseCase` *(Encrypts plaintext using recipient's public key before emitting)*
  * `ReceiveMessageStreamUseCase` *(Listens to socket, decrypts ciphertext using own private key)*
  * `SyncOfflineMessagesUseCase`
  * `GetChatHistoryUseCase`
  * `UploadMediaUseCase`
  * `MarkMessageAsReadUseCase`
  * `ObserveChatEventsUseCase`

### 5. `settings` Feature
Handles user preferences.
* **Entities:** `PrivacySetting` (lastSeenVisibility)
* **Repository Interface:** `ISettingsRepository`
* **Use Cases:**
  * `ToggleLastSeenUseCase`

---

## End-to-End Encryption (E2EE) Flow

This application is strictly store-and-forward E2EE. The backend never sees plaintext messages.

1. **Key Generation (Profile Setup):**
   * Client generates a 2048-bit RSA (or X25519) Key Pair locally using `core/crypto`.
   * **Private Key** is stored in `flutter_secure_storage` (never leaves the device).
   * **Public Key** is sent to the backend via `POST /api/user/setup`.

2. **Sending a Message (Alice to Bob):**
   * Alice's client calls `GetPublicKeyUseCase` to fetch Bob's Public Key from the server.
   * Alice's client encrypts the plaintext locally using Bob's Public Key.
   * The resulting ciphertext is sent to the server via WebSocket (`send_message`).

3. **Receiving a Message (Bob):**
   * Bob's client receives the ciphertext via WebSocket (`receive_message`).
   * Bob's client retrieves his own Private Key from `flutter_secure_storage`.
   * Bob's client decrypts the ciphertext locally to yield the plaintext for the UI.

---

## State Management & Routing

* **State Management:** Uses BLoC to manage state. Each feature has its own state managers (e.g., `AuthBloc`, `ChatBloc`). The Presentation layer only listens to states and triggers Use Cases.
* **Routing:** Implemented using `go_router`.
  * **Guard Clauses:** Routes are protected. If `CheckAuthStatusUseCase` returns no tokens, redirect to `/login`. If `isProfileComplete` is false, redirect to `/setup-profile`.

---

## Security Guidelines

1. **No Print Statements in Prod:** Never print Private Keys, Access Tokens, or Plaintext messages to the console. Use a proper logging package configured to suppress output in release mode.
2. **Certificate Pinning:** Ensure Dio is configured to validate the server's SSL certificate (or local `mkcert` CA during development) to prevent MITM attacks.
3. **Memory Wiping:** Clear Private Keys and sensitive variables from memory upon `LogoutUseCase` execution. Delete all local database caches and secure storage entries.