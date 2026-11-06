#!/usr/bin/env bash
# Checks the site before it is built and deployed. Exits with an error if anything is wrong.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
bad() { echo "FAIL: $*"; fail=1; }
ok()  { echo "ok:   $*"; }

[ -f index.html ] || { echo "FAIL: index.html is missing"; exit 1; }

# 1. Required sections
for id in home about skills projects cv contact; do
  if grep -q "id=\"$id\"" index.html; then ok "section #$id"; else bad "missing section #$id"; fi
done

# 2. No placeholder text left on the page
if grep -nEi 'FILL-IN|TODO|lorem ipsum|YOUR_[A-Z_]+' index.html; then
  bad "placeholder text found (see lines above)"
else ok "no placeholder text"; fi

# 3. Every local file the page points to exists
refs=$( { grep -oE '(src|href|poster|data-src|data-poster)="assets/[^"]+"' index.html | sed -E 's/^[a-z-]+="//; s/"$//'
          grep -oE 'url\("assets/[^"]+"\)' index.html | sed -E 's/^url\("//; s/"\)$//'; } | sort -u )
missing=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  [ -f "$p" ] || { bad "missing file: $p"; missing=1; }
done <<< "$refs"
[ "$missing" -eq 0 ] && ok "all linked files exist"

# 4. CV is a real PDF and the page links to it
cv=assets/David-Chidera-Tobias-CV.pdf
if [ -f "$cv" ] && head -c 4 "$cv" | grep -q '%PDF'; then ok "CV is a PDF"; else bad "CV is missing or not a PDF"; fi
grep -q "href=\"$cv\"" index.html && ok "page links to the CV" || bad "page does not link to the CV"

# 5. Contact and profile links
grep -q 'href="mailto:' index.html && ok "email link" || bad "no email link"
grep -q 'github.com/Davichi-1' index.html && ok "GitHub link" || bad "no GitHub link"
grep -q 'linkedin.com/in/' index.html && ok "LinkedIn link" || bad "no LinkedIn link"

# 6. Private details must not be on the page
if grep -nEi 'date of birth|marital status|joppa' index.html; then bad "private detail found on the page"; else ok "no private details on the page"; fi

# 7. No secrets in the repository
if grep -rIlE 'BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|AKIA[0-9A-Z]{16}' . --exclude-dir=.git --exclude-dir=scripts; then
  bad "a secret or private key was found in the files above"
else ok "no secrets found"; fi

# 8. HTML tags are balanced
python3 - <<'PY' || fail=1
import re, sys
s = open("index.html", encoding="utf-8").read()
s = re.sub(r"<script.*?</script>|<style.*?</style>|<!--.*?-->", "", s, flags=re.S)
bad = [t for t in ("div", "section", "article", "ul", "li", "button", "figure", "dl", "nav", "a")
       if len(re.findall(rf"<{t}[\s>]", s)) != len(re.findall(rf"</{t}>", s))]
print("FAIL: unbalanced tags: " + ", ".join(bad) if bad else "ok:   HTML tags are balanced")
sys.exit(1 if bad else 0)
PY

if [ "$fail" -eq 0 ]; then echo "All checks passed."; else echo "Validation failed."; exit 1; fi
