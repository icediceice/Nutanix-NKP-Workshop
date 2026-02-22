# Registration App Admin Guide

The registration app is a lightweight web application that manages participant session
provisioning for the workshop. It maintains a SQLite database of participants and their
assigned Educates credentials.

---

## Architecture

```
Facilitator Browser
      ↓
Registration App (Flask + SQLite)
      ↓
Educates API → Participant Sessions
      ↓
Educates Portal → Participant Browser
```

The registration app is the bridge between the facilitator's participant list and the Educates
training portal. It does not run workshops itself — it manages who has access to which session.

---

## Accessing the Admin Interface

The registration app is available at:
```
https://registration.workshop.example.com/admin
```

Default admin credentials (change before the workshop):
```
Username: admin
Password: (set during installation via ADMIN_PASSWORD env var)
```

---

## Creating a Session

A "session" in the registration app represents a workshop delivery event (e.g., "NKP Workshop
Day 1 — 2026-03-01").

1. Log in to the admin interface
2. Click **New Session**
3. Fill in:
   - Session name: `NKP Workshop March 2026`
   - Date: `2026-03-01`
   - Workshop modules: select all modules for this session
   - Participant count: `20`
4. Click **Create**

The session appears in the sessions list with status `Draft`.

---

## Importing Participants

Participants can be imported from a CSV file with headers: `name,email,track`.

Valid track values: `developer`, `infra`, `both`.

```csv
name,email,track
Alice Smith,alice@example.com,developer
Bob Jones,bob@example.com,infra
Carol White,carol@example.com,both
```

1. Open the session
2. Click **Import Participants**
3. Upload the CSV file
4. Review the import preview
5. Click **Confirm Import**

---

## Provisioning Sessions

Once participants are imported:

1. Click **Provision All**
2. The app calls the Educates API to allocate a session for each participant
3. Status changes from `Pending` to `Provisioned` for each participant
4. Each participant receives their unique session URL and credentials

Provisioning typically takes 2-5 minutes for 20 participants (sessions start in parallel).

---

## Monitoring Session Status

The **Dashboard** view shows real-time session status:

| Status | Meaning |
|--------|---------|
| Pending | Not yet provisioned |
| Provisioned | Session allocated, not yet accessed |
| Active | Participant has logged in |
| Idle | Session alive but inactive for >30 minutes |
| Expired | Session has timed out and been cleaned up |

Refresh the dashboard automatically every 60 seconds via the **Auto-refresh** toggle.

---

## Distributing Credentials

### Option 1: Email (recommended)
Click **Send Emails** to send each participant their session URL and credentials via the
configured SMTP server.

### Option 2: Printed cards
Click **Export → Print Cards** to generate a PDF of individual credential cards, one per page,
ready to cut and hand out.

### Option 3: Manual
Click on any participant row to see their individual credentials for manual distribution.

---

## Exporting Data

At the end of the workshop, export participation data for your records:

1. Click **Export → CSV**
2. The CSV includes: name, email, track, session URL, first-login time, last-active time

This data is useful for reporting, follow-up emails, and certificate generation.

---

## Extending Session Duration

If the workshop runs over time:

1. Open the session
2. Click **Extend Sessions**
3. Enter additional hours (e.g., `2`)
4. Click **Apply**

This calls the Educates API to extend the TTL on all active sessions.
