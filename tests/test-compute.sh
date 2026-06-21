#!/usr/bin/env bash
# Unit test for screen-apply's pure brightness math. No hardware, no GNOME, no root.
# Sources screen-apply (which returns early when sourced) to get the real functions.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/../bin/screen-apply"

fail=0
check(){ # desc expected actual
  if [[ "$2" == "$3" ]]; then echo "ok:   $1"; else echo "FAIL: $1 -- expected [$2] got [$3]"; fail=1; fi
}

# nl_factor: day=100, full night=NIGHT_SCALE, T clamps both ends, disabled(NIGHT_T>=DAY_T)=100
check "nl day"         100 "$(nl_factor 6500 2700 6500 55)"
check "nl night"        55 "$(nl_factor 2700 2700 6500 55)"
check "nl below-night"  55 "$(nl_factor 2000 2700 6500 55)"   # T clamped up to NIGHT_T
check "nl above-day"   100 "$(nl_factor 9000 2700 6500 55)"   # T clamped down to DAY_T
check "nl disabled"    100 "$(nl_factor 3000 6500 6500 55)"   # no ramp -> no dim

# clamp: floor, ceiling, custom upper (ARZOPA cap)
check "clamp lo"     0 "$(clamp -5)"
check "clamp hi"   100 "$(clamp 150)"
check "clamp cap"   73 "$(clamp 90 0 73)"

# compute: M T NIGHT_T DAY_T NS baseL baseN baseA arzopaMax -> "pL pN pA"
check "day full"    "60 85 73" "$(compute 100 6500 2700 6500 55 60 85 75 73)"  # arzopa 75 -> capped 73
check "night full"  "33 46 40" "$(compute 100 2700 2700 6500 55 60 85 73 73)"
check "master half" "30 42 36" "$(compute 50 6500 2700 6500 55 60 85 73 73)"
check "master zero" "0 0 0"    "$(compute 0 6500 2700 6500 55 60 85 73 73)"
check "arzopa cap"  "60 85 73" "$(compute 100 6500 2700 6500 55 60 85 90 73)"

[[ $fail == 0 ]] && echo "ALL PASS" || echo "TESTS FAILED"
exit $fail
