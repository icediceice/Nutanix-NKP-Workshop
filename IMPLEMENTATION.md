# Implementation Progress

> **Rule:** When beginning work on any task, mark it `[WIP]`. When done, mark it `[x]`.
> Any Claude session picking up this repo **must read this file first** to understand current state.

---

## Completed

- [x] Full repo scaffold — backend, frontend, cluster-init, workshop CRDs, docs, learning platform
- [x] Backend smoke-test: FastAPI on port 8000, SQLite, all endpoints verified
- [x] Frontend smoke-test: React/Vite on port 3000, proxy to backend
- [x] DRY_RUN=true mode: provisioner generates fake URLs, cluster monitor returns mock data
- [x] Remove real company/person names (G-Able, Somchai, Apinya, gable.co.th → generic examples)
- [x] Modular bundle system: `courses.yaml` restructured from fixed tracks to selectable bundles
  - Foundation workshops always included
  - 7 selectable bundles: app-development, nkp-developer-tools, fluxcd-gitops, istio-service-mesh, infra-fundamentals, cluster-operations, storage-and-dr
  - Bundles include `includes_tools` and `coherent_with` metadata
- [x] `Participant.modules` replaces `Participant.track` — stores JSON array of bundle IDs
- [x] `routers/registration.py` — `RegisterRequest.modules: List[str]`, validated against courses.yaml
- [x] `services/educates_provisioner.py` — courses.yaml-driven workshop resolver (foundation + selected bundles, deduplication)
- [x] `services/excel_parser.py` — `modules` column replaces `track`, accepts comma-separated bundle IDs
- [x] `routers/import_export.py` — updated for `modules` field
- [x] `frontend/ModuleSelector.jsx` — checkbox grid grouped by developer/infrastructure category
- [x] `frontend/RegistrationForm.jsx` — uses ModuleSelector, `modules` field, generic placeholders
- [x] `frontend/StatsBar.jsx` — removed Developer/Infra track cards (track concept eliminated)
- [x] `frontend/ParticipantTable.jsx` — shows `modules` array instead of track name
- [x] Session editing: `Session.event_date` column added, `PUT /api/sessions/{id}` endpoint
- [x] `frontend/SessionManager.jsx` — inline edit modal for session name and event date
- [x] `api.js` — added `updateSession` function
- [x] Git initialized with initial commit

---

## Pending — Phase 2

### High Priority
- [ ] Educates REST API integration (replace `_request_sessions` stub in educates_provisioner.py)
  - Research actual Educates Training Portal API endpoints
  - Implement bearer token auth
  - Handle session URL response shape
- [ ] Workshop content expansion (currently placeholder Markdown stubs in workshops/)
  - Each workshop needs 3–5 hands-on lab steps with terminal commands

### Medium Priority
- [ ] Excel bulk import UI improvements (progress indicator, better error display)
- [ ] CSV export: add event_date to headers
- [ ] Self-registration page: show active session info from `/api/sessions/active`
- [ ] Admin password: implement real backend auth endpoint instead of client-side check

### Lower Priority
- [ ] Quiz component in learning-platform/
- [ ] K8s self-deploy testing (registration-app/k8s/)
- [ ] TrainingPortal CRD capacity tuning per expected participant count

---

## Architecture Notes

### Curriculum flow
```
courses.yaml
  └─ foundation.workshops  → always provisioned
  └─ bundles[id].workshops → provisioned for selected modules (deduped)

Participant.modules = JSON array of selected bundle IDs
EducatesProvisioner._resolve_workshops() → union of foundation + bundle workshops
```

### Data model
```
Session: id, name, event_date, created_at, cluster_uid, status
Participant: id, session_id, name, email, company, modules (JSON), status,
             username, workshop_urls (JSON), error_message, registered_at, provisioned_at
```

### Running locally (DRY_RUN mode)
```bash
# Backend
cd registration-app/backend
pip install -r requirements.txt
DRY_RUN=true uvicorn main:app --reload --port 8000

# Frontend (new terminal)
cd registration-app/frontend
npm install && npm run dev
```
