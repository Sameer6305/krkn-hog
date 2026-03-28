#!/bin/bash
set -euo pipefail

STRESSNG="$(command -v stress-ng || true)"
SUPPORTED_HOGS=("cpu" "memory" "io")
HOG_TYPE="${HOG_TYPE:-cpu}"
RUN_ID="${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)-$$}"
ARTIFACT_DIR="${ARTIFACT_DIR:-.}"
JOBFILE="${JOBFILE:-${ARTIFACT_DIR}/hog-jobfile-${RUN_ID}.conf}"
OUTPUT_FILE="${OUTPUT_FILE:-${ARTIFACT_DIR}/output-${RUN_ID}.yaml}"

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

log_json() {
    local level="$1"
    local message="$2"
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","level":"%s","run_id":"%s","msg":"%s"}\n' "$ts" "$level" "$RUN_ID" "$(json_escape "$message")"
}

on_error() {
    local exit_code="$1"
    local line_number="$2"
    log_json "ERROR" "run failed (exit_code=${exit_code}, line=${line_number})"
    exit "$exit_code"
}

render_template() {
    local template_file="$1"
    [ ! -f "$template_file" ] && log_json "ERROR" "template $template_file does not exist" && exit 1
    envsubst < "$template_file" > "$JOBFILE"
}

trap 'on_error $? $LINENO' ERR

[[ -z "$STRESSNG" ]] && log_json "ERROR" "stress-ng not found in ${PATH}, impossible to run scenario" && exit 1
[[ -z "${HOG_TYPE:-}" ]] && log_json "ERROR" "hog type not selected, impossible to run scenario" && exit 1

mkdir -p "$ARTIFACT_DIR"
[ ! -w "$ARTIFACT_DIR" ] && log_json "ERROR" "artifact directory $ARTIFACT_DIR cannot be written" && exit 1

FOUND=false
for i in "${SUPPORTED_HOGS[@]}"; do
    if [[ "$i" == "$HOG_TYPE" ]]; then
        FOUND=true
        break
    fi
done

[[ "$FOUND" == false ]] && log_json "ERROR" "$HOG_TYPE not supported, impossible to run scenario" && exit 1
export DURATION="${DURATION:-30}"
export WORKERS="${WORKERS:-2}"
log_json "INFO" "starting workload (hog_type=$HOG_TYPE, duration=${DURATION}, workers=${WORKERS})"

if [[ "$HOG_TYPE" == "cpu" ]]; then
    export NUM_CPU="${NUM_CPU:-$WORKERS}"
    export CPU_METHOD="${CPU_METHOD:-all}"
    export LOAD_PERCENTAGE="${LOAD_PERCENTAGE:-80}"

    log_json "INFO" "cpu profile (num_cpu=${NUM_CPU}, cpu_method=${CPU_METHOD}, load_percentage=${LOAD_PERCENTAGE}, duration=${DURATION})"

    render_template "cpu-hog.conf.template"
elif [[ "$HOG_TYPE" == "memory" ]]; then
    export VM_BYTES="${VM_BYTES:-1g}"
    export VM_WORKERS="${VM_WORKERS:-$WORKERS}"

    log_json "INFO" "memory profile (vm_workers=${VM_WORKERS}, vm_bytes=${VM_BYTES}, duration=${DURATION})"

    render_template "memory-hog.conf.template"
else
    export STRESS_PATH="${STRESS_PATH:-/tmp}"
    export HDD_WORKERS="${HDD_WORKERS:-$WORKERS}"
    export HDD_BYTES="${HDD_BYTES:-10m}"
    export HDD_WRITE_SIZE="${HDD_WRITE_SIZE:-1m}"

    [ ! -d "$STRESS_PATH" ] && log_json "ERROR" "path $STRESS_PATH does not exist" && exit 1
    [ ! -w "$STRESS_PATH" ] && log_json "ERROR" "path $STRESS_PATH cannot be written" && exit 1

    log_json "INFO" "io profile (stress_path=${STRESS_PATH}, hdd_workers=${HDD_WORKERS}, hdd_bytes=${HDD_BYTES}, hdd_write_size=${HDD_WRITE_SIZE}, duration=${DURATION})"

    render_template "io-hog.conf.template"
fi

log_json "INFO" "artifacts (jobfile=${JOBFILE}, output_file=${OUTPUT_FILE})"

"$STRESSNG" -j "$JOBFILE" --metrics -Y "$OUTPUT_FILE"
log_json "INFO" "workload completed successfully"
cat "$OUTPUT_FILE"
