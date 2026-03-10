# CSPM Report Builder

A self-hosted tool for building cloud security reports. Connects to Wiz, imports findings, and exports professional Hebrew PDF reports.

Built for security consultants who need to document CSPM/DSPM/KSPM findings across multiple cloud environments.

![Python](https://img.shields.io/badge/python-3.12-blue)
![Flask](https://img.shields.io/badge/flask-3.1-green)
![Docker](https://img.shields.io/badge/docker-ready-blue)

---

## Quick Start

```bash
git clone https://github.com/Metoraf007/cspm-report-builder.git
cd cspm-report-builder
docker compose up --build
```

Open [http://localhost:8080](http://localhost:8080).

That's it. No database, no external dependencies beyond Docker.

---

## How It Works

The tool has 5 tabs:

1. **Report Details** — client name, environment, date, executive summary, cover image
2. **Edit Findings** — add/edit findings with severity, category, description, impact, recommendations, evidence
3. **Export** — generate PDF or HTML reports, export/import JSON state
4. **File Manager** — manage saved states and output files on the server
5. **Wizi** — connect to Wiz API, browse/search findings, import into the report

### The Report Flow

```
Wiz API  ──┐
CSV file ──┤──→  Findings List  ──→  Hebrew PDF Report
Manual    ──┘    (edit, sort,        (cover, TOC, severity chart,
                  batch edit)         per-finding pages, evidence)
```

---

## Wizi Integration

Connect to the Wiz API to pull findings directly. Requires a read-only service account.

Create a `.env` file (see `.env.example`):

```env
WIZI_CLIENT_ID=your-client-id
WIZI_CLIENT_SECRET=your-client-secret
WIZI_API_URL=https://api.il1.app.wiz.io/graphql
WIZI_AUTH_URL=https://auth.app.wiz.io/oauth/token
```

### Supported Query Types

| Query Type | Category | What it fetches |
|---|---|---|
| Issues | Mixed | Cross-category security issues (the main Wiz view) |
| Cloud Configuration | CSPM | Misconfigured cloud resources |
| Vulnerabilities | VULN | CVEs with CVSS scores, exploit info, fix versions |
| Host Configuration | HSPM | Host-level security assessments |
| Data Findings | DSPM | Sensitive data exposure (PII, secrets in storage) |
| Secrets | SECR | Exposed credentials and certificates |
| Excessive Access | EAPM | Over-privileged identities |
| Network Exposure | NEXP | Publicly exposed resources |
| Inventory / EOL | EOLM | End-of-life software and untagged resources |

### Find by ID

The search bar accepts multiple formats and runs through 6 strategies automatically:

- `EC2-005` — rule shortId (resolves via `cloudConfigurationRules`)
- `wc-id-870` — issue control/rule ID
- `e7dba598-3065-...` — full UUID (tries all 9 query types)
- `IMDSv2` — free-text fallback on issues

Results are paginated with subscription filtering.

### What Gets Imported

When you import a finding, fields are auto-mapped:

| Report Field | Mapped From |
|---|---|
| Title | Rule name |
| Description | Finding name or rule description |
| Impact | Severity + resource context |
| Technical | Cloud, subscription, region, resource type, rule details |
| Recommendations | `remediationInstructions` → description fallback → generic Hebrew |
| Policies | Top 4 frameworks from `securitySubCategories` (ISO 27001, NIST, CIS, etc.) |
| Owner | Subscription or project name |

---

## Optional Features

### AI Writing Assistant

Set `GEMINI_API_KEY` to enable "✨ שפר ניסוח" buttons on free-text fields. Supports `gemini-2.0-flash`, `gemini-2.5-flash`, `gemini-2.5-pro`.

Get a free key at [aistudio.google.com/apikey](https://aistudio.google.com/apikey).

### Authentication

Set `APP_TOKEN` to require a bearer token on all endpoints (except `/api/health`):

```yaml
# docker-compose.yml
environment:
  - APP_TOKEN=your-secret-token
```

### CSV Import

Supports two formats:
- **Wiz CSV export** — auto-detected, maps `rule.shortId`, `rule.name`, `rule.severity`, `rule.remediationInstructions`, etc.
- **Generic CSV** — auto-maps common column names (`id`, `title`, `severity`, `description`, `impact`, `recommendation`)

---

## Configuration

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8080` | Server port |
| `APP_TOKEN` | _(empty)_ | Bearer token for auth (empty = open) |
| `GEMINI_API_KEY` | _(empty)_ | Gemini API key (empty = AI disabled) |
| `WIZI_CLIENT_ID` | _(empty)_ | Wiz service account ID (empty = Wizi hidden) |
| `WIZI_CLIENT_SECRET` | _(empty)_ | Wiz service account secret |
| `WIZI_API_URL` | `https://api.il1.app.wiz.io/graphql` | Wiz GraphQL endpoint |
| `WIZI_AUTH_URL` | `https://auth.app.wiz.io/oauth/token` | Wiz OAuth endpoint |
| `RATE_LIMIT_MAX` | `30` | Max POST/DELETE requests per IP per window |
| `RATE_LIMIT_WINDOW` | `60` | Rate limit window (seconds) |
| `CLEANUP_DAYS` | `30` | Auto-delete output files after N days |

---

## UI Features

- **Dark/light theme** — toggle persisted in localStorage
- **Auto-save** — every 10 seconds + on page close, restores on reload (including in-progress form edits)
- **Keyboard shortcuts** — `J`/`K` navigate, `E` edit, `D` delete, `Ctrl+Enter` add finding, `?` help
- **Drag-and-drop** — reorder findings, drop evidence images
- **Clipboard paste** — `Ctrl+V` to attach screenshots
- **Inline editing** — click title/severity/owner in the table
- **Batch edit** — select multiple findings, change severity/priority/owner
- **Finding preview** — slide-out panel without leaving the table
- **Finding templates** — pre-built common findings for quick entry
- **Trend comparison** — import a previous JSON to see new/resolved/changed findings
- **Category badges** — visual count per category (CSPM: 5, VULN: 3, etc.)
- **Deduplication** — auto-detects duplicates during Wizi import

---

## Development

Frontend files (`index.html`, `static/`) are volume-mounted — edit and refresh.

For backend changes (`app.py`):

```bash
docker compose up --build -d
```

### Project Structure

```
app.py                    Flask backend, PDF rendering, Wiz API proxy
index.html                Builder UI entry point
static/js/builder.js      All UI logic, Wizi integration, import mapping
static/css/builder.css    Styles (dark/light themes)
assets/cover.png          Default report cover
assets/report.css         Generated report stylesheet
templates/report_template.html   Jinja2 PDF template
render_pdf_playwright.py  Standalone CLI PDF renderer
```

### API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Builder UI |
| `GET` | `/api/health` | Health check (always open, no auth) |
| `POST` | `/api/render-pdf` | Render HTML → PDF |
| `POST` | `/api/suggest` | AI phrasing suggestions |
| `POST` | `/api/upload-state` | Save report state |
| `GET` | `/api/list-states` | List saved states |
| `GET` | `/api/download-state/<id>` | Download state |
| `DELETE` | `/api/delete-state/<id>` | Delete state |
| `POST` | `/api/upload-html` | Upload HTML report |
| `GET` | `/api/list-outputs` | List output files |
| `GET` | `/api/download-output/<name>` | Download output |
| `DELETE` | `/api/delete-output/<name>` | Delete output |
| `POST` | `/api/wizi/issues` | Fetch findings (all 9 query types) |
| `POST` | `/api/wizi/find-by-id` | Search by ID/shortId/rule |
| `GET` | `/api/wizi/projects` | List Wiz projects |
| `GET` | `/api/wizi/subscriptions` | List Wiz subscriptions |
| `GET` | `/api/wizi/status` | Wiz connection status |
| `POST` | `/api/wizi/graphql` | Raw GraphQL proxy (read-only) |
| `GET` | `/api/wizi/discover` | Introspect Wiz API schema |

---

## License

MIT
