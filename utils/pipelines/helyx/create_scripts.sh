#!/bin/bash
#
# submit_job.sh - Assemble pipeline/job.sbatch from the templates and submit it.
#
# Run from the case directory:
#   /path/to/templates/submit_job.sh <JOB_NAME> <NODES> <TASKS> <TASKS_PER_NODE> <EMAIL> <TYPE>
#
#   TYPE  run   - Allrun with stage-in / stage-out around helyxSolve
#         check - checkMesh only
#   EMAIL may be an empty string ("") to use the submitting user.

set -euo pipefail

die() { echo "Error: $*" >&2; exit 1; }

if [ $# -ne 6 ]; then
    echo "Usage: $0 <JOB_NAME> <NODES> <TASKS> <TASKS_PER_NODE> <EMAIL> <TYPE>" >&2
    echo "Error: This script requires exactly 6 arguments." >&2
    exit 1
fi

JOB_NAME=$1
NODES=$2
TASKS=$3
TASKS_PER_NODE=$4
EMAIL=$5
TYPE=$6
SCDIR="$PWD"    # Script Call Directory (the case)
TPL="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"   # templates live next to this script

# --- Validate arguments ------------------------------------------------------
[[ "$JOB_NAME" =~ ^[A-Za-z0-9._-]+$ ]] \
    || die "JOB_NAME may only contain letters, digits, '.', '_' and '-' (got '$JOB_NAME')"

for v in NODES TASKS TASKS_PER_NODE; do
    [[ "${!v}" =~ ^[1-9][0-9]*$ ]] || die "$v must be a positive integer (got '${!v}')"
done

(( TASKS == NODES * TASKS_PER_NODE )) \
    || die "TASKS ($TASKS) must equal NODES x TASKS_PER_NODE ($NODES x $TASKS_PER_NODE = $(( NODES * TASKS_PER_NODE ))); the stage-in assumes the same number of ranks on every node"

[[ -z "$EMAIL" || "$EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+$ ]] \
    || die "invalid EMAIL '$EMAIL'"

case "$TYPE" in
    run|check) ;;
    *) die "Unsupported TYPE '$TYPE'. Only 'run' or 'check' are supported." ;;
esac

# --- Check that all templates exist ------------------------------------------
required=(decomposeParDict job.sbatch.header)
if [ "$TYPE" = run ]; then
    required+=(job.sbatch.presolve job.sbatch.postsolve job.sbatch.tail copy_tasks.sh send_results.sh)
    [ -f "$SCDIR/Allrun" ] || required+=(Allrun)
else
    required+=(check_mesh.sbatch)
fi
for f in "${required[@]}"; do
    [ -f "$TPL/$f" ] || die "template not found: $TPL/$f"
done

# Escape a value for use in a sed replacement (delimiter '|')
esc() { printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'; }

# Append a file to the job script, stripping Windows line endings
append() { tr -d '\r' < "$1" >> "$TMP"; }

mkdir -p "$SCDIR/system" "$SCDIR/pipeline"
OUT="$SCDIR/pipeline/job.sbatch"
TMP="$(mktemp "$SCDIR/pipeline/.job.sbatch.XXXXXX")"
trap 'rm -f "$TMP" "$TMP.awk"' EXIT

# --- decomposeParDict --------------------------------------------------------
echo "Creating decomposeParDict"
# N=$(python3 "$TPL/calcN.py" "$TASKS")   # not needed with scotch
tr -d '\r' < "$TPL/decomposeParDict" |
    sed -e "s|{{ TASKS }}|$TASKS|g" -e "s|{{ N }}|${N:-}|g" > "$SCDIR/system/decomposeParDict"

# --- Header ------------------------------------------------------------------
echo "Creating slurm batch job"
echo " - Adding header from template"
tr -d '\r' < "$TPL/job.sbatch.header" | sed \
    -e "s|{{ JOB_NAME }}|$(esc "$JOB_NAME")|g" \
    -e "s|{{ EMAIL }}|$(esc "$EMAIL")|g" \
    -e "s|{{ NODES }}|$NODES|g" \
    -e "s|{{ TASKS }}|$TASKS|g" \
    -e "s|{{ TASKS_PER_NODE }}|$TASKS_PER_NODE|g" \
    -e "s|{{ OUTPUT }}|pipeline/$(esc "$JOB_NAME").out|g" \
    -e "s|{{ OERROR }}|pipeline/$(esc "$JOB_NAME").err|g" \
    > "$TMP"

if [ "$TYPE" = check ]; then
    # --- checkMesh -----------------------------------------------------------
    echo " - Adding checkMesh section"
    append "$TPL/check_mesh.sbatch"
else
    # --- Allrun --------------------------------------------------------------
    echo " - Adding run simulation section"
    if [ ! -f "$SCDIR/Allrun" ]; then
        [ -t 0 ] || die "no Allrun in $SCDIR and no terminal to create one interactively"
        echo " - No Allrun script found. Creating $SCDIR/Allrun from the template."
        cp "$TPL/Allrun" "$SCDIR/Allrun"
        "${EDITOR:-nano}" "$SCDIR/Allrun"
    fi

    # Disable 'cd "${0%/*}"': inside a Slurm job $0 is the spool copy of the
    # script, so it would cd away from the case directory.
    tr -d '\r' < "$SCDIR/Allrun" | sed -E \
        -e 's@^([[:space:]]*cd[[:space:]]+"?\$\{0%/\*\}"?.*)$@# (disabled by submit_job.sh) \1@' \
        >> "$TMP"

    # --- Wrap the first helyxSolve with stage-in / stage-out -----------------
    echo " - Looking for helyxSolve line to insert pre- and post-solve sections"
    if grep -qE '^[[:space:]]*helyxRun.*helyxSolve' "$TMP"; then
        echo " - helyxSolve found! Inserting pre-solve and post-solve sections"
        # Templates are read with getline: awk -v would mangle backslashes.
        awk -v prefile="$TPL/job.sbatch.presolve" -v postfile="$TPL/job.sbatch.postsolve" '
            function slurp(f,    l, s) {
                s = ""
                while ((getline l < f) > 0) { sub(/\r$/, "", l); s = s l "\n" }
                close(f)
                return s
            }
            BEGIN { pre = slurp(prefile); post = slurp(postfile) }
            !done && /^[[:space:]]*helyxRun.*helyxSolve/ {
                printf "%s%s\n%s", pre, $0, post
                done = 1
                next
            }
            { print }
        ' "$TMP" > "$TMP.awk"
        mv "$TMP.awk" "$TMP"
    else
        echo " - WARNING: no 'helyxRun ... helyxSolve' line found in Allrun." >&2
        echo "   The job will run entirely on the shared filesystem, without local stage-in/out." >&2
    fi

    echo " - Adding tail from template"
    append "$TPL/job.sbatch.tail"

    install -m 0755 "$TPL/copy_tasks.sh" "$TPL/send_results.sh" "$SCDIR/pipeline/"
fi

# --- Sanity check and install ------------------------------------------------
if ! bash -n "$TMP"; then
    cp "$TMP" "$TMP.bad"
    die "the generated job script has a syntax error; inspect $TMP.bad"
fi

mv -f "$TMP" "$OUT"
echo "Job script written to $OUT"

# --- Submit ------------------------------------------------------------------
cd "$SCDIR"
echo "Submitting job"
JOBID=$(sbatch --parsable pipeline/job.sbatch) || die "sbatch failed"
echo "Submitted job $JOBID"
echo "Check pipeline/$JOB_NAME.out and pipeline/$JOB_NAME.err for job output and errors."