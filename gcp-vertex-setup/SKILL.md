---
name: gcp-vertex-setup
description: Set up a new Google Cloud account for Vertex AI end to end - $300 Free Trial, project, billing link, APIs, service account + JSON key, env vars, budget alerts, smoke test, optional Claude on Vertex. Automates everything through gcloud and stops to hand the user only the steps Claude may not do (card details, Google sign-in, accepting terms). Use when the user wants to open a Google Cloud / GCP account, get the $300 credits, set up Vertex AI or a service account, or says "להגדיר Vertex", "300 דולר קרדיטים", "service account לגוגל קלאוד".
---

# GCP + Vertex AI setup

Everything runs from `scripts/setup-vertex.ps1` (idempotent; re-run after each manual step).
Claude does the CLI work; the user does the few things Claude must not do.

## Who does what

| Step | Who | Why |
| --- | --- | --- |
| Install gcloud (`winget install --id Google.CloudSDK -e`) | Claude | CLI |
| Free Trial signup: card details, accept terms, Start | **User** | Claude never enters card numbers or creates accounts |
| `gcloud auth login` sign-in in the browser | **User** | Claude never types passwords |
| Project, billing link, APIs, SA, roles, key, env vars, budget, smoke test | Claude | script |
| Org policy override (Workspace orgs only) | **Org admin** | needs org-level permission |
| Claude on Vertex: upgrade to paid + Model Garden "Enable" | **User**, or Claude browser after explicit yes | accepts terms and changes billing; trial credit does not cover partner models |

## Flow

1. **Ask** (one AskUserQuestion): Google account email; new project ID (globally unique, lowercase, e.g. `vertex-lab-<name>-2026`); want Claude on Vertex (paid) yes/no; Veo output to bucket yes/no (`-WithStorage`).
2. **gcloud present?** `gcloud --version`. Missing → `winget install --id Google.CloudSDK -e`, then tell the user to reopen the terminal.
3. **Free Trial** (manual). Tell the user:
   > Open https://console.cloud.google.com/freetrial signed in as `<email>`. If this account never had Google Cloud, Google asks for card details and starts a $300 credit for 90 days. The card is for verification; nothing is charged without a manual upgrade. Tell me when you see the Console.

   Optional with Claude in Chrome (domain console.cloud.google.com must be allowed): navigate there, screenshot each screen for the user, and stop before any card field, terms checkbox or Start button. Never fill or click those.
4. **Sign-in** (manual). Run `gcloud auth login <email>` in the background; ask the user to finish the browser sign-in. Confirm with `gcloud auth list`.
5. **Run the script**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\gcp-vertex-setup\scripts\setup-vertex.ps1" -Project <id> -Account <email> [-WithStorage]
   ```
   Exit codes → action:
   - `10` not logged in → back to step 4.
   - `11` no open billing account → Free Trial not finished; back to step 3.
   - `12` several billing accounts → show the list, ask which, re-run with `-BillingAccount`.
   - `13` org policy blocks keys → give the user the printed admin command for their org admin. Suggest a personal Gmail account instead if no admin is available.
   - smoke-test WARN → wait 2 minutes, re-run (idempotent).
6. **Models**: do not hardcode IDs; they change every few months. List what exists with `gcloud ai model-garden models list --model-filter=gemini` (also `veo`, `lyria`, `imagen`), pick the highest version per role (text, flash, tts, image, video, music), and confirm each with one tiny `generateContent` call (Veo: `predictLongRunning`) before reporting it. Text/TTS/music/image models live in `global`; Veo in `us-central1`. A listed model can still 404 or 400 if it is not enabled for the project: skip it.
7. **Claude on Vertex** (only if asked). Warn first: not covered by the $300, billed to the card. Needs Billing → Upgrade to paid account, then Model Garden → Claude card → Enable. Both are manual, or Claude in Chrome clicks them only after the user says yes to that specific click. Then `py -m pip install -U "anthropic[vertex]"` and use `AnthropicVertex(project_id=..., region="global")` with the model ID copied from the Model Garden card.
8. **Report**: project, SA email, key path, env vars set, budget, smoke-test result, model IDs. Remind: the key is a secret; never commit it; delete with `gcloud iam service-accounts keys delete`.

## Gotchas

- Trial credit excludes: partner models (Claude), Gemini API via AI Studio, Marketplace, GPUs, quota increases.
- `invalid_rapt` / hourly reauth on Workspace accounts → that is why the SA key exists; scripts use `GOOGLE_APPLICATION_CREDENTIALS`, never user ADC.
- Budget uses `EXCLUDE_ALL_CREDITS`, otherwise it reads $0 until credit runs out.
- Remaining credit balance has no CLI; it is only at console.cloud.google.com/billing/credits.
- Emergency stop on spend: `gcloud billing projects unlink <project>`.
