#!/usr/bin/env bash
# net-stress.sh — home network stress / health test & router benchmark
#
# Levels 1-4 are safe health/load tests. Levels 5-6 are ROUTER-KILLERS: they
# deliberately overwhelm the router's NAT/connection-tracking table to find its
# ceiling. They will likely drop your whole household offline and may need a
# router reboot to recover — gated behind an explicit confirmation flag.
#
# Diagnoses the TP-Link Deco failure mode: NAT/client(MAC)-table overflow breaks
# IPv4 (needs NAT+ARP) while IPv6 (SLAAC) keeps working. github.com is IPv4-only,
# so it's the canary.
#
# Usage:   ./net-stress.sh [level] [--i-accept-downtime]
#   1  quick     ~10s   light poll — healthy right now?
#   2  moderate  ~30s   everyday-heavy load (default)
#   3  tough     ~1-2m  realistic doom-sync-scale hammering
#   4  brutal    ~3-5m  heavy; approaches the ceiling
#   5  siege      ~1m   TAKEDOWN: 600 concurrent + churn — will crush a BE65
#   6  meltdown   ~2m   TAKEDOWN: 1200 concurrent + churn + UDP/DNS flood —
#                       only a router with a big conntrack table survives
#   (accepts the name too: ./net-stress.sh siege --i-accept-downtime)
#
# Run in a normal terminal.
set -u

EXTREME=0; CHURN_W=0; CHURN_S=0; UDP_W=0
case "${1:-2}" in
  1|quick)    LEVEL=1; NAME=QUICK;    SEQ=10; CONC="10 25";       CLONES=4;  MODULES=1; BURST=20;  DL=2  ;;
  2|moderate) LEVEL=2; NAME=MODERATE; SEQ=30; CONC="25 50";       CLONES=8;  MODULES=1; BURST=50;  DL=4  ;;
  3|tough)    LEVEL=3; NAME=TOUGH;    SEQ=40; CONC="50 100";      CLONES=16; MODULES=3; BURST=60;  DL=8  ;;
  4|brutal)   LEVEL=4; NAME=BRUTAL;   SEQ=60; CONC="100 200 300"; CLONES=24; MODULES=5; BURST=150; DL=12 ;;
  5|siege)    LEVEL=5; NAME=SIEGE;    EXTREME=1; CONC="200 400 600";   CHURN_W=50;  CHURN_S=25; UDP_W=0   ;;
  6|meltdown) LEVEL=6; NAME=MELTDOWN; EXTREME=1; CONC="400 800 1200"; CHURN_W=100; CHURN_S=45; UDP_W=300 ;;
  *) echo "Usage: $0 [1-6 | quick|moderate|tough|brutal|siege|meltdown] [--i-accept-downtime]"; exit 1 ;;
esac
CONFIRM="${2:-}"
CONC_MAX="${CONC##* }"
IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
GW=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')
IP=$(ipconfig getifaddr "${IFACE:-en0}" 2>/dev/null || echo "?")

echo "=== net-stress  level $LEVEL ($NAME)  $(date '+%Y-%m-%d %H:%M:%S') ==="
echo "  iface=$IFACE  gateway=$GW  ip=$IP"
WORK=$(mktemp -d); cd "$WORK"
# Clean up ALL background workers on exit or Ctrl-C (levels 5/6 spawn churn/flood
# loops that would otherwise orphan and keep hammering the network).
cleanup(){ trap - INT TERM EXIT; kill $(jobs -p) 2>/dev/null; pkill -P $$ 2>/dev/null; rm -rf "$WORK" 2>/dev/null; }
trap cleanup INT TERM EXIT

mark() { local pct=0; [ "$2" -gt 0 ] && pct=$(( $1 * 100 / $2 ))
  if   [ "$pct" -ge 98 ]; then printf '\033[32m✓\033[0m'
  elif [ "$pct" -ge 80 ]; then printf '\033[33m~\033[0m'
  else                         printf '\033[31m✗\033[0m'; fi; }
line() { printf "  %-30s %5s/%-5s  %s\n" "$1" "$2" "$3" "$(mark "$2" "$3")"; }
conc_http() { local d; d=$(mktemp -d)
  for i in $(seq 1 "$1"); do ( curl "$2" -sS -m 12 -o /dev/null "$3" 2>/dev/null && : > "$d/$i" ) & done; wait
  find "$d" -type f 2>/dev/null | wc -l | tr -d ' '; rm -rf "$d"; }
probe4() { local ok=0; for i in $(seq 1 "${1:-10}"); do [ "$(curl -4 -sS -m 4 -o /dev/null -w '%{http_code}' https://github.com 2>/dev/null)" = 200 ] && ok=$((ok+1)); done; echo "$ok"; }
probe6() { local ok=0; for i in $(seq 1 "${1:-10}"); do [ "$(curl -6 -sS -m 4 -o /dev/null -w '%{http_code}' https://www.google.com 2>/dev/null)" = 200 ] && ok=$((ok+1)); done; echo "$ok"; }

run_battery() {
  ok=0; for i in $(seq 1 "$SEQ"); do [ "$(curl -sS -m 6 -o /dev/null -w '%{http_code}' https://github.com 2>/dev/null)" = 200 ] && ok=$((ok+1)); done; line "github seq (IPv4-only)" "$ok" "$SEQ"
  for n in $CONC; do line "IPv4 concurrent x$n" "$(conc_http "$n" -4 https://www.google.com)" "$n"; done
  line "IPv6 concurrent x$CONC_MAX (ctrl)" "$(conc_http "$CONC_MAX" -6 https://www.google.com)" "$CONC_MAX"
  ok=0; for i in $(seq 1 "$SEQ"); do [ "$(curl -sS -m 8 -o /dev/null -w '%{http_code}' 'https://codeload.github.com/octocat/Hello-World/tar.gz/refs/heads/master' 2>/dev/null)" = 200 ] && ok=$((ok+1)); done; line "codeload tarball" "$ok" "$SEQ"
  REPOS="octocat/Hello-World octocat/Spoon-Knife magit/transient jwiegley/use-package magnars/dash.el magnars/s.el rejeep/f.el emacs-straight/compat emacs-straight/let-alist joaotavora/yasnippet bbatsov/projectile justbur/emacs-which-key abo-abo/swiper abo-abo/hydra purcell/exec-path-from-shell domtronn/all-the-icons.el emacs-straight/auctex doomemacs/snippets emacs-straight/org-mode syl20bnr/spacemacs emacs-evil/evil hlissner/doom-emacs emacsmirror/markdown-mode bbatsov/prelude"
  i=0; for r in $REPOS; do i=$((i+1)); [ "$i" -gt "$CLONES" ] && break; ( git clone --depth 1 -q "https://github.com/$r.git" "c$i" 2>/dev/null && : > "ok$i" ) & done; wait
  line "parallel git clones" "$(ls ok* 2>/dev/null | wc -l | tr -d ' ')" "$CLONES"; rm -rf c* ok*
  ok=0; for i in $(seq 1 "$MODULES"); do git clone --depth 1 -q https://github.com/doomemacs/modules "dm$i" 2>/dev/null && ok=$((ok+1)); rm -rf "dm$i"; done; line "doomemacs/modules clone" "$ok" "$MODULES"
  ok=0; for i in $(seq 1 "$BURST"); do nc -z -w 3 -G 3 github.com 443 >/dev/null 2>&1 && ok=$((ok+1)); done; line "rapid nc github:443" "$ok" "$BURST"
  for i in $(seq 1 "$DL"); do ( curl -sS -m 45 -o /dev/null -w '%{size_download}\n' "https://speed.cloudflare.com/__down?bytes=10000000" 2>/dev/null >> dl.txt ) & done; wait
  ok=$(grep -c 10000000 dl.txt 2>/dev/null); [ -z "$ok" ] && ok=0; line "parallel 10MB downloads" "$ok" "$DL"; rm -f dl.txt
  echo "=== done (level $NAME) ==="
  echo "  legend: ✓ >=98%   ~ 80-97%   ✗ <80%    (IPv6 ctrl ✗ may just mean no IPv6 on your net)"
  echo "  IPv6 ctrl ✓ but IPv4 ✗/~  ->  Deco table full: clear offline clients / reboot; fix = NAT Proxmox guests behind the host."
}

run_takedown() {
  if [ "$CONFIRM" != "--i-accept-downtime" ]; then
    echo
    echo "  !!  Level $LEVEL ($NAME) is a ROUTER-KILLER. It will likely knock your ENTIRE"
    echo "  !!  household offline and may require a router reboot to recover."
    echo "  !!  Run only when you can tolerate downtime, then confirm:"
    echo "         $0 $LEVEL --i-accept-downtime"
    exit 2
  fi
  ulimit -n 65536 2>/dev/null || ulimit -n 10240 2>/dev/null || true
  ulimit -u 4096  2>/dev/null || true
  echo "  (raised fd/proc limits; if you see 'fork'/'too many open files', the MAC is the bottleneck —"
  echo "   lower the numbers or drive the test from a Linux box.)"

  echo "  baseline:      IPv4 $(probe4)/10   IPv6 $(probe6)/10"
  echo "  concurrency ladder (watch where IPv4 collapses):"
  for n in $CONC; do line "IPv4 concurrent x$n" "$(conc_http "$n" -4 https://www.google.com)" "$n"; done

  echo "  >>> ASSAULT for ${CHURN_S}s: holding $CONC_MAX connections + $CHURN_W churn workers$([ "$UDP_W" -gt 0 ] && echo " + $UDP_W UDP/DNS-flood workers")"
  deadline=$(( SECONDS + CHURN_S ))
  # (a) hold many simultaneous connections
  for i in $(seq 1 "$CONC_MAX"); do curl -sS -m "$((CHURN_S+15))" -o /dev/null "https://speed.cloudflare.com/__down?bytes=10000000" 2>/dev/null & done
  # (b) rapid open/close churn — piles up TIME_WAIT/conntrack entries
  for w in $(seq 1 "$CHURN_W"); do ( while [ "$SECONDS" -lt "$deadline" ]; do nc -z -w 1 -G 1 github.com 443 >/dev/null 2>&1; done ) & done
  # (c) UDP/DNS flood — long-lived, un-closable conntrack entries (level 6)
  if [ "$UDP_W" -gt 0 ]; then
    RES="1.1.1.1 8.8.8.8 9.9.9.9 208.67.222.222 8.8.4.4 1.0.0.1"
    DOM="example.com github.com google.com cloudflare.com wikipedia.org apple.com"
    for u in $(seq 1 "$UDP_W"); do ( idx=$(( (u % 6) + 1 ))
      r=$(echo "$RES" | tr ' ' '\n' | sed -n "${idx}p"); d=$(echo "$DOM" | tr ' ' '\n' | sed -n "${idx}p")
      while [ "$SECONDS" -lt "$deadline" ]; do dig +tries=1 +time=1 @"$r" "$d" >/dev/null 2>&1; done ) & done
  fi
  # mid-storm reading: can a NORMAL new connection still get through?
  sleep $(( CHURN_S / 2 ))
  echo "  MID-STORM:     IPv4 $(probe4 8)/8    IPv6 $(probe6 8)/8   <- BE65: IPv4 craters, IPv6 survives"
  wait 2>/dev/null

  echo "  recovery (approx; each step ~20s):"
  t=0
  while [ "$t" -le 120 ]; do
    p=$(probe4 6); printf "    +%3ss  IPv4 %s/6  %s\n" "$t" "$p" "$(mark "$p" 6)"
    [ "$p" -ge 6 ] && { echo "    -> recovered after ~${t}s"; break; }
    sleep 20; t=$(( t + 20 ))
  done
  [ "$t" -gt 120 ] && echo "    -> still degraded after 120s: reboot the Deco to clear its table."
  echo "=== done (level $NAME) ==="
  echo "  Verdict: if IPv4 flatlined mid-storm while IPv6 held, the router's NAT/conntrack table was"
  echo "  exhausted (expected on a BE65). A router that keeps IPv4 alive here has the headroom you want."
}

if [ "$EXTREME" = 1 ]; then run_takedown; else run_battery; fi
