# CSPM Report Builder

A self-hosted web tool for building, managing, and exporting Cloud Security Posture Management (CSPM) reports. Built for security consultants who need to document cloud security findings and export professional Hebrew-language PDF reports.

![Python](https://img.shields.io/badge/python-3.12-blue)
![Flask](https://img.shields.io/badge/flask-3.1-green)
![Docker](https://img.shields.io/badge/docker-ready-blue)

## What it does

- **Report builder UI** — tabbed interface for report details, findings, export, file management, and Wizi integration
- **Finding categories** — CSPM, KSPM, DSPM, VULN, NEXP, EAPM, HSPM, SECR, EOLM with auto-prefixed IDs
- **Finding templates** — pre-built common findings (S3 public bucket, open security groups, MFA, etc.) for quick entry
- **Risk score** — auto-calculated risk score based on severity distribution, shown in the executive summary
- **PDF export** — server-side rendering via Playwright/Chromium with proper Hebrew RTL layout, headers, footers, and page breaks
- **Dynamic table of contents** — clickable links to each finding with severity badges
- **AI writing assistant** — optional Gemini integration to improve phrasing of report fields, with a selectable model (gemini-2.0-flash, 2.5-flash, 2.5-pro)
- **Custom cover image** — upload your own cover image from the UI, or use the default
- **State management** — save/load report configurations as JSON, both locally and on the server
- **CSV import** — bulk import findings from CSV exports (auto-maps common column names)
- **Wizi integration** — connect to Wiz (Wizi) API to fetch findings directly, with 9 query types, subscription/project filtering, shortId search, and one-click import to report
- **Find by ID** — search findings by UUID, rule ID (wc-id-xxx), or rule shortId (EC2-005) with paginated results and subscription filtering
- **Smart field mapping** — imported findings auto-populate description, impact, technical details, recommendations, and policies with relevant data
- **Framework detection** — policies field shows top 4 relevant frameworks (ISO 27001, NIST CSF, CIS Controls, PCI-DSS, etc.) instead of raw control references
- **Finding preview panel** — slide-out panel showing all finding details without leaving the table
- **Batch edit** — select multiple findings and change severity, priority, or owner in bulk
- **Drag-and-drop reorder** — reorder findings in the table by dragging
- **Inline quick-edit** — click title, severity, or owner directly in the table to edit
- **Finding deduplication** — auto-detects duplicate findings during Wizi import
- **Dark/light theme** — toggle between dark and light themes, persisted in localStorage
- **Owner field** — track the team/entity responsible for fixing each finding
- **File manager** — upload, download, and manage state files and output reports on the server
- **Keyboard navigation** — J/K to navigate findings, E to edit, D to delete, ? for shortcuts overlay
- **Trend comparison** — import a previous JSON snapshot to see new, resolved, and severity-changed findings
- **Report versioning** — track report version number across revisions
- **Multiple evidence images** — attach multiple screenshots per finding with drag-and-drop, paste, and lightbox preview
- **Multi-language reports** — toggle between Hebrew and English report output
- **Auto-save** — automatic save to localStorage every 10 seconds with visual indicator
- **Defaults system** — save and load default report details (client name, environment, etc.)
- **Category count badges** — visual badges showing finding count per category
- **Toast notifications** — non-intrusive feedback for all actions
- **Progress stepper** — visual progress indicator across report building steps
- **Rate limiting** — configurable per-IP rate limiting on mutating API endpoints

## Quick Start

### Prerequisites

- Docker and Docker Compose

### Run locally

```bash
git clone https://github.com/Metoraf007/cspm-report-builder.git
cd cspm-report-builder
docker compose up --build
```

Open [http://localhost:8080](http://localhost:8080) in your browser.

### Enable authentication

Set the `APP_TOKEN` variable in `docker-compose.yml`:

```yaml
environment:
  - APP_TOKEN=your-secret-token-here
```

When set, all requests (except `/api/health`) require either:
- `Authorization: Bearer <token>` header, or
- `?token=<token>` query parameter (for browser downloads)

### Enable AI writing assistant

Set your Gemini API key as an environment variable before starting the container:

```bash
export GEMINI_API_KEY=your-api-key-here
docker compose up -d
```

Get a free key at [aistudio.google.com/apikey](https://aistudio.google.com/apikey). When enabled, "✨ שפר ניסוח" buttons appear below free-text fields, and a model selector dropdown appears in the report details section. Supported models: `gemini-2.0-flash`, `gemini-2.5-flash`, `gemini-2.5-pro`.

### Enable Wizi (Wiz) integration

Create a `.env` file (see `.env.example`) with your Wiz service account credentials:

```env
WIZI_CLIENT_ID=your-client-id
WIZI_CLIENT_SECRET=your-client-secret
WIZI_API_URL=https://api.il1.app.wiz.io/graphql
WIZI_AUTH_URL=https://auth.app.wiz.io/oauth/token
```

The service account needs read permissions. When configured, a "Wizi" tab appears in the UI.

### Configuration

| Environment Variable | Default | Description |
|---|---|---|
| `PORT` | `8080` | Server port |
| `APP_TOKEN` | _(empty)_ | Bearer token for auth (empty = open access) |
| `CLEANUP_DAYS` | `30` | Auto-delete output files older than N days (0 = disabled) |
| `GEMINI_API_KEY` | _(empty)_ | Google Gemini API key for AI writing assistant (empty = disabled) |
| `WIZI_CLIENT_ID` | _(empty)_ | Wiz service account client ID (empty = Wizi tab hidden) |
| `WIZI_CLIENT_SECRET` | _(empty)_ | Wiz service account client secret |
| `WIZI_API_URL` | `https://api.il1.app.wiz.io/graphql` | Wiz GraphQL API endpoint |
| `WIZI_AUTH_URL` | `https://auth.app.wiz.io/oauth/token` | Wiz OAuth token endpoint |
| `RATE_LIMIT_MAX` | `30` | Max POST/DELETE requests per IP per window (0 = disabled) |
| `RATE_LIMIT_WINDOW` | `60` | Rate limit window in seconds |
| `FLASK_DEBUG` | `0` | Enable Flask debug mode |

## Wizi Integration

The Wizi tab connects to the Wiz API and supports 9 query types:

| Query Type | Category | Description |
|---|---|---|
| Issues | General | Cross-category security issues |
| Cloud Configuration | CSPM | Cloud misconfiguration findings |
| Vulnerabilities | VULN | Software vulnerability findings |
| Host Configuration | HSPM | Host-level configuration assessments |
| Data Findings | DSPM | Sensitive data exposure findings |
| Secrets | SECR | Exposed secrets and credentials |
| Excessive Access | EAPM | Over-privileged identity findings |
| Network Exposure | NEXP | Network exposure findings |
| Inventory / EOL | EOLM | End-of-life and inventory findings |

### Find by ID

The quick search bar at the top of the Wizi tab supports multiple identifier formats:

| Format | Example | Description |
|---|---|---|
| Rule shortId | `EC2-005` | Cloud configuration rule short identifier (visible in Wiz console) |
| Rule ID | `wc-id-870` | Issue source rule identifier |
| UUID | `e7dba598-3065-...` | Full finding UUID |
| Free text | `IMDSv2` | Falls back to free-text search on issues |

The search runs through 6 strategies in order: direct UUID lookup across all 9 query types, issue sourceRule filter, config rule filter, host config rule filter, shortId resolution via `cloudConfigurationRules`, and free-text search fallback. Results are paginated (5 per page) with subscription filtering support.

### Smart Field Mapping

When importing findings from Wizi, fields are automatically mapped:

| Report Field | Source |
|---|---|
| Title | Rule name |
| Description | Finding name (what was actually found) |
| Impact | Severity-based context + resource name |
| Technical | Cloud, subscription, region, resource details + rule description excerpt |
| Recommendations | Actionable sentences extracted from rule description, or domain-specific defaults |
| Policies | Top 4 relevant frameworks detected from `securitySubCategories` |
| Owner | Subscription name or project name |

### Framework Detection

The policies field maps Wizi's `securitySubCategories` (which can contain 50+ individual control references) to recognized framework names, sorted by relevance:

1. ISO 27001
2. NIST CSF
3. CIS Controls
4. PCI-DSS
5. SOC 2
6. NIST 800-53
7. DORA
8. NIS2
9. CSA CCM
10. AWS Security Best Practices

Only the top 4 matching frameworks are shown per finding.

## Usage

### Building a report

1. Fill in the **report details** tab (client name, environment, date, executive summary)
2. Switch to the **findings** tab and add findings — each gets an auto-generated ID (CSPM-001, CSPM-002...)
3. For evidence, you can:
   - **Drag and drop** an image onto the drop zone
   - **Paste from clipboard** (Ctrl+V / Cmd+V) — great for screenshots
   - **Click** to browse for a file
4. Use **Ctrl+Enter** to quickly add a finding and start the next one
5. Sort findings by severity using the sort button
6. Duplicate similar findings with the "שכפל" button
7. Use **J/K** keys to navigate the findings table, **E** to edit, **D** to delete
8. Use **finding templates** dropdown to quickly add common findings
9. Click the **👁** button to preview a finding in the slide-out panel
10. Click severity chips in the table to cycle through severity levels
11. Drag the **⠿** handle to reorder findings

### Importing from Wizi

1. Go to the **Wizi** tab
2. **Quick search**: enter a rule shortId (e.g. `EC2-005`), rule ID, or UUID in the search bar, optionally filter by subscription
3. **Browse**: select a query type, filter by project/subscription/severity/status, click fetch
4. Select findings using checkboxes (or select all)
5. Click **ייבוא נבחרים** to import into the report with auto-mapped fields
6. Use **batch edit** to change severity/priority/owner on multiple findings at once

### Exporting

- **PDF (server)** — renders a professional PDF with headers, footers, severity charts, and page breaks
- **HTML** — opens the report in a new tab or downloads as a file
- **JSON** — export/import the full report state for backup or sharing

### CSV Import

Click "ייבוא ממצאים מ-CSV" to bulk import findings. The importer supports two formats:

#### Wiz Cloud Configuration Findings (auto-detected)

Export from Wiz: Cloud Configuration Findings → Group by Rule → Export CSV. The importer auto-detects the Wiz format and maps:

| Wiz CSV column | → Report field |
|---|---|
| `rule.shortId` | Finding ID |
| `rule.name` | Title |
| `rule.severity` | Severity |
| `rule.description` | Description |
| `rule.risks` | Impact |
| `rule.remediationInstructions` | Recommendations |
| `rule.cloudProvider`, `serviceType`, `targetNativeType` | Technical details |
| `analytics.totalFindingCount`, `resourceCount` | Technical details (counts) |
| `rule.externalReferences` | Policies / standards |

#### Generic CSV

For other CSV sources, the importer auto-maps common column names:

| Expected columns | Mapped from |
|---|---|
| ID | `id`, `finding id`, `מזהה` |
| Title | `title`, `name`, `issue`, `כותרת` |
| Severity | `severity`, `risk`, `חומרה` |
| Description | `description`, `details`, `תיאור` |
| Impact | `impact`, `השפעה` |
| Recommendation | `recommendation`, `remediation`, `fix`, `המלצה` |

### Auto-save & Defaults

- Your work is automatically saved to localStorage every 10 seconds and on page close, with a visual indicator showing save status
- When you reopen the page, it restores your last session
- Save default report details (client name, environment, etc.) to pre-fill new reports
- Clear defaults from the report details tab

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Builder UI |
| `POST` | `/api/render-pdf` | Render HTML to PDF |
| `POST` | `/api/upload-state` | Upload JSON state |
| `GET` | `/api/download-state/<id>` | Download state file |
| `GET` | `/api/list-states` | List saved states |
| `DELETE` | `/api/delete-state/<id>` | Delete a state |
| `POST` | `/api/upload-html` | Upload HTML report |
| `GET` | `/api/download-output/<name>` | Download output file |
| `GET` | `/api/list-outputs` | List output files |
| `DELETE` | `/api/delete-output/<name>` | Delete output file |
| `GET` | `/api/health` | Health check (always open) |
| `POST` | `/api/suggest` | AI phrasing suggestions (requires `GEMINI_API_KEY`) |
| `GET` | `/api/wizi/status` | Check Wizi integration status |
| `GET` | `/api/wizi/projects` | List Wizi projects |
| `GET` | `/api/wizi/subscriptions` | List Wizi subscriptions |
| `POST` | `/api/wizi/issues` | Fetch Wizi findings (all 9 query types) |
| `POST` | `/api/wizi/find-by-id` | Search by ID/shortId/rule with pagination |
| `POST` | `/api/wizi/graphql` | Raw GraphQL proxy (for debugging) |
| `GET` | `/api/wizi/discover` | Introspect available Wizi API fields |

## Project Structure

```
.
├── app.py                      # Flask backend + PDF rendering + Wizi API proxy
├── index.html                  # Builder UI (entry point)
├── static/
│   ├── css/
│   │   └── builder.css         # Builder UI styles (dark/light themes)
│   └── js/
│       └── builder.js          # Builder UI logic + Wizi integration + import mapping
├── assets/
│   ├── cover.png               # Default report cover image
│   └── report.css              # Generated report stylesheet
├── templates/
│   └── report_template.html    # Jinja2 report template
├── render_pdf_playwright.py    # Standalone PDF renderer (CLI)
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── .env.example                # Environment variable template
└── README.md
```

## Development

HTML, CSS, and JS files are volume-mounted in `docker-compose.yml` — edit and refresh, no rebuild needed.

For Python changes (`app.py`), rebuild:

```bash
docker compose up --build -d
```

## License

MIT
