#!/bin/sh
# Show the status of my personal Claude sessions. Read-only: it only reads status lines from the box.
# Needs ~/.config/claude-status/pull.json (get it once with:  curl -sL ecfm.github.io/b|sh -s CODE).
# Usage:  curl -sL ecfm.github.io/s|sh          sessions that are open or ended in the last 24 hours
#         curl -sL ecfm.github.io/s|sh -s all   every session the box still keeps (30 days)
f="$HOME/.config/claude-status/pull.json"
[ -f "$f" ] || { echo "no $f yet. First run:  curl -sL ecfm.github.io/b|sh -s CODE"; exit 1; }
command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }
exec python3 - "$f" "$1" <<'PYEOF'
import datetime as dt, json, subprocess, sys

cfg = json.load(open(sys.argv[1]))
# curl reads the address from stdin, so the read token is not in any command line
out = subprocess.run(["curl", "-sL", "-m", "40", "-K", "-"], capture_output=True, text=True,
                     input='url = "%s?token=%s"\n' % (cfg["url"], cfg["read_token"])).stdout
try:
    data = json.loads(out)
except ValueError:
    sys.exit("the box did not answer with JSON: %r" % out[:80])
if not data.get("ok"):
    sys.exit("the box refused: %s" % data.get("error"))
now = dt.datetime.now(dt.timezone.utc)


def age(r):
    try:
        return (now - dt.datetime.fromisoformat(r.get("updated_at", ""))).total_seconds()
    except ValueError:
        return 1e12


def ago(s):
    return "%dm" % (s / 60) if s < 3600 else "%dh" % (s / 3600) if s < 172800 else "%dd" % (s / 86400)


def one_line(t, n):
    t = " ".join((t or "").split())
    return t if len(t) <= n else t[: n - 1] + "…"


recs = sorted(data["records"], key=lambda r: ({"waiting": 0, "running": 1}.get(r.get("state"), 2), age(r)))
shown = [r for r in recs if sys.argv[2] == "all" or r.get("state") != "ended" or age(r) < 86400]
for r in shown:
    print("%-8s %-14s %-5s %s" % (r.get("state", "?").upper(), r.get("host", "?"), ago(age(r)), one_line(r.get("title"), 70)))
    last = " ".join((r.get("last_assistant") or "").split())
    if last:
        print("         > %s" % (last if len(last) <= 110 else "…" + last[-109:]))
    if r.get("state") != "ended":
        print("         $ %s" % r.get("resume", ""))
hidden = len(recs) - len(shown)
print("%d shown%s" % (len(shown), ", %d older ended sessions hidden (add: -s all)" % hidden if hidden else ""))
PYEOF
