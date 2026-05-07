# fairpipe Fairness Validator Action

A GitHub composite action that runs [`fairpipe validate`](https://github.com/JobCollins/fairness_pipeline_dev_toolkit) in CI/CD — computes fairness metrics, writes a markdown report to the job summary, and optionally fails the workflow when a demographic parity threshold is exceeded.

---

## Quick Start

```yaml
- uses: SvrusIO/fairpipe-action@v1
  with:
    csv: data/predictions.csv
    y-true: y_true
    sensitive: gender
    y-pred: y_pred
    threshold: "0.05"
```

---

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `csv` | yes | — | Path to the data file (CSV or Parquet: `.csv`, `.parquet`, `.pq`), relative to the repository root. |
| `y-true` | yes | — | Column name for ground-truth labels. |
| `sensitive` | yes | — | Sensitive attribute column name(s). Comma-separated for multiple attributes, e.g. `"gender,race"`. |
| `y-pred` | no | `""` | Column name for predicted labels (classification). |
| `score` | no | `""` | Column name for predicted scores (regression / ranking). |
| `threshold` | no | `"0.05"` | Fairness threshold for demographic parity difference. The action sets `passed=false` and optionally exits 1 when DPD exceeds this value. |
| `fail-on-violation` | no | `"true"` | Set to `"true"` to exit 1 when the threshold is exceeded. Set to `"false"` to surface the result without failing the workflow. |
| `fairpipe-version` | no | `"latest"` | fairpipe version to install. Use `"latest"` for the newest release or pin to a specific version such as `"0.6.5"`. |
| `with-ci` | no | `"true"` | Compute bootstrap confidence intervals for reported metrics. |
| `min-group-size` | no | `"30"` | Minimum number of samples required per sensitive group. |

---

## Outputs

| Output | Description |
|--------|-------------|
| `passed` | `"true"` if DPD is within threshold, `"false"` otherwise. |
| `dpd` | Demographic parity difference as a string (4 decimal places), or `"N/A"`. |
| `report-path` | Absolute path to the written markdown report file. |

---

## Usage Examples

### Classification — single sensitive attribute

```yaml
name: Fairness Check

on: [push, pull_request]

jobs:
  fairness:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: SvrusIO/fairpipe-action@v1
        with:
          csv: data/predictions.csv
          y-true: y_true
          y-pred: y_pred
          sensitive: gender
          threshold: "0.05"
```

### Classification — multiple sensitive attributes

```yaml
- uses: SvrusIO/fairpipe-action@v1
  with:
    csv: data/predictions.csv
    y-true: y_true
    y-pred: y_pred
    sensitive: "gender,race"
    threshold: "0.10"
```

### Regression — score-based fairness

```yaml
- uses: SvrusIO/fairpipe-action@v1
  with:
    csv: data/scores.csv
    y-true: actual_score
    score: predicted_score
    sensitive: age_group
    threshold: "0.05"
```

### Pin a specific fairpipe version

```yaml
- uses: SvrusIO/fairpipe-action@v1
  with:
    csv: data/predictions.csv
    y-true: y_true
    y-pred: y_pred
    sensitive: gender
    fairpipe-version: "0.6.5"
```

### Audit-only mode — report without failing

```yaml
- uses: SvrusIO/fairpipe-action@v1
  with:
    csv: data/predictions.csv
    y-true: y_true
    y-pred: y_pred
    sensitive: gender
    fail-on-violation: "false"
```

### Consume outputs in downstream steps

```yaml
- name: Run fairness check
  id: fairness
  uses: SvrusIO/fairpipe-action@v1
  with:
    csv: data/predictions.csv
    y-true: y_true
    y-pred: y_pred
    sensitive: gender

- name: Print result
  run: |
    echo "Passed: ${{ steps.fairness.outputs.passed }}"
    echo "DPD: ${{ steps.fairness.outputs.dpd }}"
    echo "Report: ${{ steps.fairness.outputs.report-path }}"
```

### Parquet input

```yaml
- uses: SvrusIO/fairpipe-action@v1
  with:
    csv: data/predictions.parquet
    y-true: y_true
    y-pred: y_pred
    sensitive: gender
```

---

## Job Summary

When the action runs, it appends a fairness report to the [GitHub Actions job summary](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#adding-a-job-summary). The summary includes:

- Pass/fail status with the DPD value and threshold
- Full per-group metric table from `fairpipe validate`
- Bootstrap confidence intervals (when `with-ci: "true"`)

---

## How It Works

1. **Set up Python 3.11** using `actions/setup-python@v5`.
2. **Install fairpipe** — either the latest release or a pinned version.
3. **Run `fairpipe validate`** — builds the command from inputs (no shell injection risk: all inputs are passed via environment variables and expanded into a bash array), captures the markdown report, parses the DPD, and compares it against the threshold.
4. **Write the job summary** with the full report.
5. **Set step outputs** (`passed`, `dpd`, `report-path`).
6. **Exit 1** when `fail-on-violation: "true"` and DPD exceeds threshold; exit 0 otherwise.

---

## Requirements

- Runs on any `ubuntu-*` or `macos-*` runner (Python 3.11 is installed by the action).
- Your repository must contain a data file (CSV or Parquet) with prediction and label columns.

---

## License

Apache 2.0 — see [LICENSE](LICENSE).

---

*Powered by [fairpipe](https://github.com/JobCollins/fairness_pipeline_dev_toolkit)*
