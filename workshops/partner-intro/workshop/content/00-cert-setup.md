---
title: "Certificate Setup"
---

## Before We Begin -- Trust the Workshop Certificate

This workshop runs on a private Kubernetes cluster with a **self-signed CA certificate**. Your browser will show security warnings unless you install the CA cert first.

> **This takes 60 seconds and prevents all certificate errors for the rest of the workshop.**

---

## Step 1 -- Download the Certificate

Click below to extract the CA certificate from the cluster:

```terminal:execute
command: kubectl get secret kommander-ca -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > ~/kommander-ca.crt && echo "Certificate saved to ~/kommander-ca.crt"
```

Now download it to your laptop. **Right-click** the link below and choose **Save link as...** :

```terminal:execute
command: echo "Download URL:" && echo "https://$SESSION_HOSTNAME/files/kommander-ca.crt"
```

If the above download link does not work, you can copy the certificate text and save it manually:

```terminal:execute
command: cat ~/kommander-ca.crt
```

Copy the full output (including `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`) and save it as `kommander-ca.crt` on your laptop.

---

## Step 2 -- Install the Certificate

### macOS

1. Double-click `kommander-ca.crt` -- it opens **Keychain Access**
2. Find `kommander-ca` in the login keychain
3. Double-click it, expand **Trust**, set **When using this certificate** to **Always Trust**
4. Close and enter your password

### Windows

1. Double-click `kommander-ca.crt`
2. Click **Install Certificate** → **Local Machine** → **Next**
3. Select **Place all certificates in the following store** → **Browse** → **Trusted Root Certification Authorities**
4. Click **Next** → **Finish**

### Linux (Chrome/Chromium)

1. Open `chrome://settings/certificates`
2. Click **Authorities** → **Import**
3. Select `kommander-ca.crt`, check **Trust this certificate for identifying websites**
4. Click **OK**

---

## Step 3 -- Verify

**Close all browser tabs for this workshop**, then reopen this page. If the certificate is installed correctly, you will see a lock icon (or no warning) in the address bar.

> **Tip**: If you still see a warning on some pages, try a hard refresh (`Ctrl+Shift+R` or `Cmd+Shift+R`).

---

Ready? Click **Next** to begin the workshop.
