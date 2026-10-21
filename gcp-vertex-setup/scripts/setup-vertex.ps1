<#
Sets up a Google Cloud project for Vertex AI with a service account key.
Idempotent: safe to re-run; every step checks before it creates.

Usage:
  powershell -ExecutionPolicy Bypass -File setup-vertex.ps1 -Project my-vertex-lab-2026 -Account me@gmail.com
  (add -BillingAccount XXXXXX-XXXXXX-XXXXXX when more than one open billing account exists)

Exit codes: 0 done; 10 not logged in; 11 no open billing account; 12 several billing accounts, pass one;
            13 key creation blocked by org policy.
#>
param(
  [Parameter(Mandatory)] [string] $Project,
  [Parameter(Mandatory)] [string] $Account,
  [string] $BillingAccount = "",
  [string] $SaName = "vertex-ai-sa",
  [int]    $BudgetUsd = 300,
  [switch] $WithStorage
)

$ErrorActionPreference = "Continue"
function Step($m) { Write-Host "`n== $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "   OK  $m" -ForegroundColor Green }
function Stop-With($code, $m) { Write-Host "   STOP $m" -ForegroundColor Yellow; exit $code }

Step "Account"
$accounts = gcloud auth list --format="value(account)" 2>$null
if ($accounts -notcontains $Account) { Stop-With 10 "Not logged in as $Account. Run: gcloud auth login $Account" }
gcloud config set account $Account 2>$null | Out-Null
Ok $Account

Step "Project"
gcloud projects describe $Project --format="value(projectId)" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  gcloud projects create $Project --name="Vertex Lab"
  if ($LASTEXITCODE -ne 0) { exit 1 }
}
gcloud config set project $Project 2>$null | Out-Null
Ok $Project

Step "Billing"
$enabled = gcloud billing projects describe $Project --format="value(billingEnabled)" 2>$null
if ($enabled -ne "True") {
  if (-not $BillingAccount) {
    $open = @(gcloud billing accounts list --filter="open=true" --format="value(name.basename())" 2>$null)
    if ($open.Count -eq 0) { Stop-With 11 "No open billing account. Free Trial signup not done yet." }
    if ($open.Count -gt 1) { Stop-With 12 "Several open billing accounts: $($open -join ', '). Re-run with -BillingAccount." }
    $BillingAccount = $open[0]
  }
  gcloud billing projects link $Project --billing-account=$BillingAccount
  if ($LASTEXITCODE -ne 0) { exit 1 }
} else {
  $BillingAccount = (gcloud billing projects describe $Project --format="value(billingAccountName)").Split("/")[-1]
}
Ok "billing account $BillingAccount"

Step "APIs"
$apis = @("aiplatform.googleapis.com","iam.googleapis.com","iamcredentials.googleapis.com",
          "cloudresourcemanager.googleapis.com","cloudbilling.googleapis.com","billingbudgets.googleapis.com")
if ($WithStorage) { $apis += "storage.googleapis.com" }
gcloud services enable @apis --project=$Project
if ($LASTEXITCODE -ne 0) { exit 1 }
Ok ($apis -join ", ")

Step "Service account"
$saEmail = "$SaName@$Project.iam.gserviceaccount.com"
gcloud iam service-accounts describe $saEmail --project=$Project 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  gcloud iam service-accounts create $SaName --display-name="Vertex AI scripts" --project=$Project
  if ($LASTEXITCODE -ne 0) { exit 1 }
}
$roles = @("roles/aiplatform.user")
if ($WithStorage) { $roles += "roles/storage.objectAdmin" }
foreach ($r in $roles) {
  gcloud projects add-iam-policy-binding $Project --member="serviceAccount:$saEmail" --role=$r --condition=None --quiet 2>$null | Out-Null
}
Ok "$saEmail ($($roles -join ', '))"

Step "Key"
$keyDir = Join-Path $env:USERPROFILE ".gcloud\keys"
New-Item -ItemType Directory -Force $keyDir | Out-Null
$key = Join-Path $keyDir "$Project-sa.json"
if (-not (Test-Path $key)) {
  $out = gcloud iam service-accounts keys create $key --iam-account=$saEmail --project=$Project 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    if ($out -match "disableServiceAccountKeyCreation|not allowed") {
      Stop-With 13 "Org policy blocks key creation. An org admin must run: gcloud resource-manager org-policies disable-enforce iam.disableServiceAccountKeyCreation --project=$Project"
    }
    Write-Host $out; exit 1
  }
}
Ok $key

Step "Environment variables (User scope)"
[Environment]::SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", $key, "User")
[Environment]::SetEnvironmentVariable("GOOGLE_CLOUD_PROJECT", $Project, "User")
[Environment]::SetEnvironmentVariable("GOOGLE_CLOUD_LOCATION", "global", "User")
[Environment]::SetEnvironmentVariable("GOOGLE_GENAI_USE_VERTEXAI", "True", "User")
Ok "set; open a new shell to pick them up"

Step "Budget"
$existing = gcloud billing budgets list --billing-account=$BillingAccount --format="value(displayName)" 2>$null
if ($existing -notcontains "Vertex $BudgetUsd credit") {
  gcloud billing budgets create --billing-account=$BillingAccount --display-name="Vertex $BudgetUsd credit" `
    --budget-amount="${BudgetUsd}USD" --credit-types-treatment=EXCLUDE_ALL_CREDITS `
    --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0
}
Ok "alerts at 50/90/100% of $BudgetUsd USD"

Step "Smoke test with the service account key"
$env:GOOGLE_APPLICATION_CREDENTIALS = $key
$token = gcloud auth application-default print-access-token 2>$null
if (-not $token) {
  gcloud auth activate-service-account --key-file=$key 2>$null | Out-Null
  $token = gcloud auth print-access-token --account=$saEmail
  gcloud config set account $Account 2>$null | Out-Null
}
$url = "https://aiplatform.googleapis.com/v1/projects/$Project/locations/global/publishers/google/models/gemini-3.8-flash:generateContent"
$body = '{"contents":[{"role":"user","parts":[{"text":"Reply with the single word: ready"}]}]}'
try {
  $r = Invoke-RestMethod -Method Post -Uri $url -Headers @{Authorization="Bearer $token"} -ContentType "application/json" -Body $body
  Ok ("Gemini says: " + $r.candidates[0].content.parts[0].text.Trim())
} catch {
  Write-Host "   WARN smoke test failed (IAM can take ~2 min to propagate): $($_.Exception.Message)" -ForegroundColor Yellow
}
exit 0
