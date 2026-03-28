# krkn-hog

Containerized resource stress workload generator for chaos and resilience testing.

## Project Scope

`krkn-hog` is a workload utility, not a data warehouse.

It intentionally focuses on generating controlled stress profiles using `stress-ng` for:
- CPU pressure
- Memory pressure
- Disk I/O pressure

This repository does **not** currently implement:
- Python ETL pipelines
- PostgreSQL warehouse modeling
- Pandera data validation
- SQL ELT transformations
- BI/dashboard analytics layers

## Architecture

High-level runtime flow:
1. Container starts `run.sh`.
2. Runtime parameters are loaded from environment variables.
3. A stress profile template is rendered using `envsubst`.
4. Run-specific artifact paths are generated using `RUN_ID`.
5. `stress-ng` executes the generated job file.
6. Metrics are written to a run-specific output file and printed to stdout.

Core files:
- `run.sh`: workload type selection and validation
- `*.conf.template`: `stress-ng` template profiles
- `Containerfile`: runtime image build
- `.github/workflows/build.yaml`: CI image build and publish

## Execution Contract

Required runtime dependency:
- `stress-ng`

Supported `HOG_TYPE` values:
- `cpu`
- `memory`
- `io`

Common environment variables:
- `HOG_TYPE` (default: `cpu`)
- `DURATION` (default: `30`)
- `WORKERS` (default: `2`)
- `RUN_ID` (default: UTC timestamp + process id)
- `ARTIFACT_DIR` (default: current working directory)
- `JOBFILE` (default: `${ARTIFACT_DIR}/hog-jobfile-${RUN_ID}.conf`)
- `OUTPUT_FILE` (default: `${ARTIFACT_DIR}/output-${RUN_ID}.yaml`)

Type-specific variables:
- CPU: `CPU_METHOD`, `LOAD_PERCENTAGE`, `NUM_CPU`
- Memory: `VM_BYTES`, `VM_WORKERS`
- IO: `STRESS_PATH`, `HDD_WORKERS`, `HDD_BYTES`, `HDD_WRITE_SIZE`

## Production Readiness Direction

Immediate priorities are tracked via ADRs and should focus on:
1. Runtime safety and deterministic behavior
2. CI quality and security gates
3. Operational observability

See:
- `docs/adr/0001-project-scope-and-target-architecture.md`
- `docs/operations-runbook.md`

## License

Apache 2.0
