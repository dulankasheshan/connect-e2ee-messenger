# 💬 Connect Chat — Secure Real-Time Messaging App

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Socket.io](https://img.shields.io/badge/Socket.io-black?style=for-the-badge&logo=socket.io&badgeColor=010101)
![Clean Architecture](https://img.shields.io/badge/Architecture-Clean_Feature_First-success?style=for-the-badge)
![Security](https://img.shields.io/badge/Security-RSA_E2EE-critical?style=for-the-badge)

**Connect** is a production-ready, highly secure, real-time messaging application built with **Flutter**. It strictly implements **End-to-End Encryption (E2EE)** and is structured using a **Feature-First Clean Architecture** to ensure maximum scalability, maintainability, and privacy.
---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Tech Stack](#tech-stack)
3. [Folder Structure](#folder-structure)
4. [Domain Layer Specification](#domain-layer-specification)
5. [End-to-End Encryption (E2EE) Flow](#end-to-end-encryption-e2ee-flow)
6. [Advanced Messaging Features](#advanced-messaging-features)
7. [Local Persistence & Offline Sync](#local-persistence--offline-sync)
8. [Performance & UI Optimization](#performance--ui-optimization)
9. [State Management & Routing](#state-management--routing)
10. [Security Guidelines](#security-guidelines)

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
| **Local Database** | isar                   | High-performance NoSQL offline caching |
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
The core messaging engine handling REST history, offline sync, real-time Socket events, and rich media.
* **Entities:** * `Message` (id, senderId, receiverId, decryptedText, mediaUrl, status, createdAt, isEdited, isDeleted, replyToMsgId)
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
    * `EditMessageUseCase` *(Encrypts updated text and broadcasts edit event)*
    * `DeleteMessageUseCase` *(Broadcasts "Delete for Everyone" event)*
    * `ClearAllChatHistoryUseCase` *(Wipes local conversation data)*
    * `GetRecentChatsUseCase` *(Retrieves the latest messages for the home screen list)*

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

## Advanced Messaging Features

* **Real-time Edit & Delete:** Users can edit messages post-delivery or completely retract them using the "Delete for Everyone" feature, synchronized instantly across all connected clients.
* **Swipe-to-Reply Context:** WhatsApp-style threaded replies. Users can swipe right on any message bubble to trigger a quoted reply preview.
* **Image & Media Sharing:** Fully integrated image picker with multipart API uploads. Media URLs are transmitted securely through the WebSocket payload and rendered instantly with fallback loading indicators.
* **Real-time Read Receipts:** Live tracking of message statuses (`sent`, `delivered`, `read`) using dynamic UI tick indicators.

---

## Local Persistence & Offline Sync

* **Isar NoSQL Database:** Used as the single source of truth for the Chat UI to provide an instant, offline-first experience.
* **Background Syncing:** Upon socket reconnection, the app automatically fetches and persists any messages missed while the device was offline or terminated.
* **Real-time List Updates:** The home screen (Recent Chats) actively listens to background socket streams, instantly updating unread counters, timestamps, and last-message previews without requiring manual refreshes.

---

## Performance & UI Optimization

1. **Memory Protection (Payload Limits):** Text inputs are capped at 5000 characters at the UI level. This prevents memory overflow and UI thread-freezing during the CPU-intensive RSA encryption process of massive payloads.
2. **Widget Lifecycle Integrity:** `ValueKey` bindings are strictly applied within the `ListView.builder`. This prevents Flutter's element tree from recycling old widget states, ensuring correct UI rendering for dynamic elements like quoted replies and edited messages.
3. **Dynamic Constraints:** Implementation of `IntrinsicWidth` ensures chat bubbles expand smoothly to accommodate long texts or images without exceeding responsive screen boundaries.

---

## State Management & Routing

* **State Management:** Uses BLoC to manage state. Each feature has its own state managers (e.g., `AuthBloc`, `ChatBloc`, `ChatListBloc`). The Presentation layer only listens to states and triggers Use Cases.
* **Routing:** Implemented using `go_router`.
    * **Guard Clauses:** Routes are protected. If `CheckAuthStatusUseCase` returns no tokens, redirect to `/login`. If `isProfileComplete` is false, redirect to `/setup-profile`.

---

## Security Guidelines

1. **No Print Statements in Prod:** Never print Private Keys, Access Tokens, or Plaintext messages to the console. Use a proper logging package configured to suppress output in release mode.
2. **Certificate Pinning:** Ensure Dio is configured to validate the server's SSL certificate (or local `mkcert` CA during development) to prevent MITM attacks.
3. **Memory Wiping:** Clear Private Keys and sensitive variables from memory upon `LogoutUseCase` execution. Delete all local database caches and secure storage entries.

---

## Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0 or higher)
* Dart SDK
* A running instance of the **Connect Chat Backend** (Node.js/MySQL).

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/____Project_Username____/Connect-Chat-Flutter.git](https://github.com/____Project_Username____/Connect-Chat-Flutter.git)
   cd Connect-Chat-Flutter
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration:**
   Create a `.env` file in the root directory of your project to securely store your backend URLs.
   ```env
   # .env
   API_BASE_URL=https://10.0.2.2:5443/api
   SOCKET_URL=https://10.0.2.2:5443
   ```
   *(Note: Use `10.0.2.2` for Android Emulators to connect to localhost, or your computer's local Wi-Fi IP like `192.168.x.x` for physical devices).*

4. **Generate Data Classes & Isar DB Schemas:**
   Run the build runner to generate the necessary files for the Isar database models and Dependency Injection.
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **SSL Certificate Pinning (Android Setup):**
   To prevent Man-in-the-Middle (MITM) attacks and allow local secure connections via `mkcert`, native SSL Certificate Pinning has been configured.
   If your local development IP or SSL certificate changes, update the domain and SHA-256 PIN in `android/app/src/main/res/xml/network_security_config.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <network-security-config>
       <domain-config cleartextTrafficPermitted="false">
           <domain includeSubdomains="true">10.22.93.136</domain>
           <trust-anchors>
               <certificates src="user" />
               <certificates src="system" />
           </trust-anchors>
           <pin-set expiration="2028-01-01">
               <pin digest="SHA-256">6SKY+cqhHw6edZiQGL3kGXzWCkG98bEERcB+7EnA=</pin>
           </pin-set>
       </domain-config>
   </network-security-config>
   ```

6. **Run the App:**
   ```bash
   flutter run
   ```

---

## API & WebSocket Integration

The frontend seamlessly communicates with the Node.js backend using `dio` for RESTful requests and `socket_io_client` for real-time WebSocket events. Endpoints are centralized in the `ApiEndpoints` class and mapped directly to the `.env` configurations.

**REST Endpoints Overview (`API_BASE_URL`):**
* **Auth:** OTP generation, verification, and JWT token rotation (`/auth/send-otp`, `/auth/refresh`).
* **Profile:** E2EE Public Key upload, profile metadata updates (`/user/setup`, `/user/me`).
* **Discover:** User searching, blocklist management, and fetching recipient public keys.
* **Chat & Media:** Chat history pagination (`/messages/history`), offline sync (`/messages/sync`), and multipart file uploads (`/media/upload`).

**WebSocket Events (`SOCKET_URL`):**
* The client connects via WebSockets to emit and listen to strictly typed events such as `join_chat`, `send_message`, `receive_message`, `msg_status_update`, `message_edited`, and `message_deleted`.