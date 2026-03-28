# Operations Runbook

This runbook defines how to execute, observe, and troubleshoot `krkn-hog` safely in production-like environments.

## 1. Runtime Preconditions

- Container image is built from `Containerfile` and includes `stress-ng`.
- Runtime has write access to `ARTIFACT_DIR` (defaults to current working directory).
- Runtime has write access to `STRESS_PATH` for `io` mode.
- Required environment variables are either provided or defaults are acceptable.

## 2. Standard Execution Profiles

### CPU stress profile

- `HOG_TYPE=cpu`
- `WORKERS=2`
- `LOAD_PERCENTAGE=80`
- `DURATION=30`
- `RUN_ID=cpu-burst-001` (optional)

### Memory stress profile

- `HOG_TYPE=memory`
- `WORKERS=2`
- `VM_BYTES=1g`
- `DURATION=30`
- `RUN_ID=memory-burst-001` (optional)

### IO stress profile

- `HOG_TYPE=io`
- `WORKERS=2`
- `STRESS_PATH=/tmp`
- `HDD_BYTES=10m`
- `HDD_WRITE_SIZE=1m`
- `DURATION=30`
- `RUN_ID=io-burst-001` (optional)

## 3. Metrics Expectations

`run.sh` executes:

- `stress-ng -j ${JOBFILE} --metrics -Y ${OUTPUT_FILE}`

Expected artifact and output behavior:

- `JOBFILE` must be generated with a run-scoped name (default includes `RUN_ID`).
- `OUTPUT_FILE` must be generated with a run-scoped name (default includes `RUN_ID`).
- `OUTPUT_FILE` must be printed to stdout at process end.
- Non-zero process exit code means run failure and should be treated as an alertable event.

Logging expectations:

- Operational logs are emitted as JSON lines with `ts`, `level`, `run_id`, and `msg`.

Minimum health checks per run:

1. Process exit code is `0`.
2. `OUTPUT_FILE` exists and is non-empty.
3. Start/end timestamps and scenario parameters are retained by the caller/orchestrator logs.

## 4. Failure Handling

Failures are fatal by design (strict shell mode):

- Missing `stress-ng`
- Unsupported `HOG_TYPE`
- Invalid or non-writable IO path
- Any command failure during template generation or execution

Operational policy:

1. Mark run as failed immediately.
2. Capture stderr/stdout and full environment configuration (excluding secrets).
3. Retry only after root-cause classification.

## 5. Troubleshooting Guide

### Error: stress-ng not found

- Cause: missing runtime dependency.
- Action: rebuild image or verify package installation in `Containerfile`.

### Error: unsupported hog type

- Cause: invalid `HOG_TYPE`.
- Action: set `HOG_TYPE` to one of `cpu`, `memory`, `io`.

### Error: path does not exist / cannot be written

- Cause: invalid `STRESS_PATH` or filesystem permissions.
- Action: mount/create writable path and re-run.

### output file missing

- Cause: execution failed before completion.
- Action: inspect container logs, verify template render step and write permissions.

### run artifacts overwritten or mixed across runs

- Cause: shared output path or manually overridden non-unique filenames.
- Action: use unique `RUN_ID` values or unique `OUTPUT_FILE`/`JOBFILE` paths per run.

## 6. Alerting Recommendations

At minimum, alert on:

- Consecutive run failures >= 2
- Any non-zero exit code
- Missing or empty `OUTPUT_FILE`

Optional SLO for scheduled environments:

- Successful runs >= 99% over trailing 7 days

## 7. Change Management

Any change to:

- `run.sh`
- `*.conf.template`
- `Containerfile`

must include:

1. `shellcheck` clean run for shell changes.
2. Evidence that run-scoped `OUTPUT_FILE` is still produced and emitted.
3. Updated runbook section if runtime behavior changed.
