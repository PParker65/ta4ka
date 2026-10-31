#!/bin/sh
# Deploy dykyi/public to Cloudflare Pages and attach dykyiboss.com + www.
# Refuses to run without CLOUDFLARE_API_TOKEN. Never prints the token.
set -eu

cd "$(dirname "$0")/.."

missing_scopes() {
  cat <<'EOF' >&2
Refusing to deploy: CLOUDFLARE_API_TOKEN is not set, and this script does not use a saved Wrangler login.

Create a Cloudflare API token with these scopes, then export CLOUDFLARE_API_TOKEN:

  Account — Cloudflare Pages — Edit
  Account — Account Settings — Read
  User — User Details — Read
  Zone — Zone — Read
  Zone — DNS — Edit
  Zone — Zone Settings — Edit
  Zone — Firewall Services — Read
    (Edit only if an existing country block must be removed. Do not add one.)

Optional: CLOUDFLARE_ACCOUNT_ID if the token can see more than one account.
EOF
}

if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
  missing_scopes
  exit 1
fi

PROJECT=dykyiboss
APEX=dykyiboss.com
PAGES_HOST="${PROJECT}.pages.dev"

echo "Deploying ${PROJECT} to Cloudflare Pages..."
npx --yes wrangler@4 pages deploy public --project-name "$PROJECT" --commit-dirty=true

api() {
  method=$1
  path=$2
  body=${3:-}
  if [ -n "$body" ]; then
    curl -sS -X "$method" "https://api.cloudflare.com/client/v4${path}" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "$body"
  else
    curl -sS -X "$method" "https://api.cloudflare.com/client/v4${path}" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json"
  fi
}

ACCOUNT=${CLOUDFLARE_ACCOUNT_ID:-}
if [ -z "$ACCOUNT" ]; then
  ACCOUNT=$(api GET /accounts | python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or [];
print(r[0]["id"] if len(r)==1 else (_ for _ in ()).throw(SystemExit("Set CLOUDFLARE_ACCOUNT_ID; token sees %d accounts" % len(r))))')
fi

ZONE=$(api GET "/zones?name=${APEX}" | python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("result") or [];
print(r[0]["id"] if r else (_ for _ in ()).throw(SystemExit("Zone dykyiboss.com was not found on this token")))')

for host in "$APEX" "www.${APEX}"; do
  echo "Attaching ${host}..."
  api POST "/accounts/${ACCOUNT}/pages/projects/${PROJECT}/domains" "{\"name\":\"${host}\"}" >/tmp/dykyi-domain.json || true
  python3 - <<'PY' /tmp/dykyi-domain.json
import json, sys
data = json.load(open(sys.argv[1]))
if data.get("success"):
    raise SystemExit(0)
errors = data.get("errors") or []
# 8000018 / already added is fine
text = json.dumps(errors)
if "already" in text.lower() or any(e.get("code") in (8000018, 8000021) for e in errors):
    raise SystemExit(0)
print(text, file=sys.stderr)
raise SystemExit(1)
PY
done

echo "Ensuring proxied CNAMEs..."
python3 - "$ZONE" "$PAGES_HOST" <<'PY'
import json, os, sys, urllib.request
zone, target = sys.argv[1], sys.argv[2]
token = os.environ["CLOUDFLARE_API_TOKEN"]
names = {"dykyiboss.com": "dykyiboss.com", "www.dykyiboss.com": "www"}

def call(method, path, body=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        "https://api.cloudflare.com/client/v4" + path,
        data=data,
        method=method,
        headers={"Authorization": "Bearer " + token, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as res:
        return json.load(res)

existing = call("GET", f"/zones/{zone}/dns_records?per_page=100")
rows = existing.get("result") or []
for fqdn, name in names.items():
    match = [r for r in rows if r.get("name") == fqdn and r.get("type") in ("A", "AAAA", "CNAME")]
    payload = {"type": "CNAME", "name": name, "content": target, "proxied": True, "ttl": 1}
    if not match:
        created = call("POST", f"/zones/{zone}/dns_records", payload)
        if not created.get("success"):
            raise SystemExit(created)
        print("created", fqdn)
        continue
    current = match[0]
    if current.get("type") == "CNAME" and current.get("content", "").rstrip(".").lower() == target and current.get("proxied"):
        print("ok", fqdn)
        continue
    updated = call("PUT", f"/zones/{zone}/dns_records/{current['id']}", payload)
    if not updated.get("success"):
        raise SystemExit(updated)
    print("updated", fqdn)
PY

echo "Turning on Always Use HTTPS..."
api PATCH "/zones/${ZONE}/settings/always_use_https" '{"value":"on"}' | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("success"), d'

echo "Checking country blocks..."
python3 - "$ZONE" <<'PY'
import json, os, sys, urllib.request
zone = sys.argv[1]
token = os.environ["CLOUDFLARE_API_TOKEN"]

def get(path):
    req = urllib.request.Request(
        "https://api.cloudflare.com/client/v4" + path,
        headers={"Authorization": "Bearer " + token},
    )
    try:
        with urllib.request.urlopen(req) as res:
            return json.load(res), None
    except Exception as exc:
        return None, str(exc)

blocked = False
for path in (
    f"/zones/{zone}/firewall/rules",
    f"/zones/{zone}/rulesets/phases/http_request_firewall_custom/entrypoint",
):
    data, err = get(path)
    if err or not data or not data.get("success"):
        print("Could not read", path, err or data)
        print("Firewall Services Read is missing or the phase is empty. Confirm in the dashboard that no country block exists.")
        continue
    blob = json.dumps(data).lower()
    if "ip.geoip.country" in blob or "ip.src.country" in blob:
        print("Country block found in", path)
        print(json.dumps(data)[:2000])
        blocked = True
if blocked:
    raise SystemExit("Remove the country block before calling dykyiboss.com worldwide. This script does not delete firewall rules.")
print("No country block seen in the rules this token can read.")
PY

echo "Deploy requested. Confirm https://${APEX} and https://www.${APEX} after certificate issuance."
