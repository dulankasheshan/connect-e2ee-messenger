# Native Public Key Pinning (SPKI) Implementation Guide

This document outlines the standard procedure for implementing Subject Public Key Info (SPKI) pinning natively on both Android and iOS for a Flutter application. This approach ensures enterprise-grade security against Man-In-The-Middle (MITM) attacks while avoiding the need to update the application every 3 months when the SSL certificate renews.

## 1. Extracting the Public Key Hash
Before configuring the native platforms, you must extract the Base64-encoded SHA-256 hash of your server's Public Key.

Run the following OpenSSL command in your terminal, replacing `your-production-api.com` with your actual domain:

```bash
openssl s_client -servername your-production-api.com -connect your-production-api.com:443 < /dev/null 2>/dev/null \
| openssl x509 -pubkey -noout \
| openssl pkey -pubin -outform der \
| openssl dgst -sha256 -binary \
| openssl enc -base64
```

*Note: Keep the output string safe. You will need it for both Android and iOS configurations. It is highly recommended to also generate a backup pin (e.g., from your Root CA's public key).*

---

## 2. Android Implementation

Android handles certificate and public key pinning via the Network Security Configuration XML file.

### Step 2.1: Create the Configuration File
Create a new file at `android/app/src/main/res/xml/network_security_config.xml`. (Create the `xml` directory if it does not exist).

### Step 2.2: Add Configuration Details
Paste the following XML, replacing the domain and pin digests with your actual data:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">your-production-api.com</domain>
        <pin-set expiration="2028-01-01"> <pin digest="SHA-256">YOUR_PRIMARY_BASE64_HASH_HERE=</pin>
            <pin digest="SHA-256">YOUR_BACKUP_BASE64_HASH_HERE=</pin>
        </pin-set>
    </domain-config>

    <debug-overrides>
        <trust-anchors>
            <certificates src="user" />
            <certificates src="system" />
        </trust-anchors>
    </debug-overrides>
</network-security-config>
```

### Step 2.3: Link Configuration in AndroidManifest.xml
Open `android/app/src/main/AndroidManifest.xml` and add the `android:networkSecurityConfig` attribute inside the `<application>` tag:

```xml
<application
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:label="connect"
    android:networkSecurityConfig="@xml/network_security_config"
    ... >
```

---

## 3. iOS Implementation

Apple handles pinning via App Transport Security (ATS) settings in the `Info.plist` file.

### Step 3.1: Open Info.plist
Navigate to `ios/Runner/Info.plist` and open it in your code editor.

### Step 3.2: Add NSPinnedDomains Configuration
Add the following keys inside the main `<dict>` tag of your `Info.plist`, replacing the domain and hash values accordingly:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSPinnedDomains</key>
    <dict>
        <key>your-production-api.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSPinnedLeafIdentities</key>
            <array>
                <dict>
                    <key>SPKI-SHA256-BASE64</key>
                    <string>YOUR_PRIMARY_BASE64_HASH_HERE=</string>
                </dict>
                <dict>
                    <key>SPKI-SHA256-BASE64</key>
                    <string>YOUR_BACKUP_BASE64_HASH_HERE=</string>
                </dict>
            </array>
        </dict>
    </dict>
</dict>
```

## Conclusion
Once implemented, the OS will automatically reject any connection to `your-production-api.com` if the public key does not match the pinned hashes, providing robust protection against MITM attacks.