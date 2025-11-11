#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/git-push-prof"
mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
TRACE="$LOG_DIR/trace2-$TS.json"
RAW="$LOG_DIR/raw-$TS.log"

echo "Tracing to: $TRACE"
echo "Raw output: $RAW"

# Enable detailed Git tracing
export GIT_TRACE2_EVENT="$TRACE"
export GIT_TRACE2_PERF="$TRACE"
export GIT_TRACE_PACKET=1
export GIT_CURL_VERBOSE=1

# Run the push and capture stdout/stderr (don’t hide progress)
{ /usr/bin/time -v git push "$@" ; } 2>&1 | tee "$RAW"
STATUS=${PIPESTATUS[0]}

echo
echo "---- Phase timing summary ----"
# Parse Trace2 JSON-ish lines to aggregate region timings
awk '
  BEGIN{ FS="\\|"; OFS=""; }
  /region_enter/ {
    split($0,a,"\\|"); t=a[2]; sub(/.*ts:/,"",t); sub(/,.*/,"",t);
    split($0,b,"region_enter: "); key=b[2];
    start[key]=t;
  }
  /region_leave/ {
    split($0,a,"\\|"); t=a[2]; sub(/.*ts:/,"",t); sub(/,.*/,"",t);
    split($0,b,"region_leave: "); key=b[2];
    if (key in start) { dur=t-start[key]; sum[key]+=dur; count[key]++; delete start[key]; }
  }
  END {
    for (k in sum) printf "%-25s %.3f s (%d)\n", k, sum[k], count[k];
  }
' "$TRACE" 2>/dev/null | sort

echo "------------------------------"
echo "Trace: $TRACE"
echo "Raw:   $RAW"
exit $STATUS
