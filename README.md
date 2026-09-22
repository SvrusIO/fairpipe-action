# fairpipe Fairness Validator Action

A GitHub composite action that runs [fairpipe](https://github.com/JobCollins/fairness_pipeline_dev_toolkit) in CI/CD — computes fairness metrics, writes a markdown report to the job summary, and optionally fails the workflow when a fairness threshold is exceeded.

It has two modes:

| Mode | Selected by | Runs | Gates |
|------|-------------|------|-------|
| `fairness-check` | `csv:` | `fairpipe validate` | Tabular predictions — demographic parity, equalized odds |
| `llm-fairness-check` | `config:` | `fairpipe llm-eval` | LLM fairness evals — counterfactual, refusal, toxicity, stereotype |

The mode is inferred from which input you set. Setting both `csv` and `config`, or neither, is a usage error.

---

## Quick Start

### `fairness-check` — tabular predictions

```yaml
- uses: SvrusIO/fairpipe-action@v2
  with:
    csv: data/predictions.csv
    y-true: y_true
    sensitive: gender
    y-pred: y_pred
    threshold: "0.05"
```

### `llm-fairness-check` — LLM fairness evals

```yaml
- uses: SvrusIO/fairpipe-action@v2
  with:
    config: llm_eval.yml
    metric: "refusal_rate_disparity"
    threshold: "0.25"
    fail-on-violation: "true"
```

Requires fairpipe **0.10.0 or later**, which is when `fairpipe llm-eval` was added. The action checks this after install and fails with a direct message rather than letting the CLI report an unrecognised subcommand. The examples gate `refusal_rate_disparity` so a caveated (illustrative) fixture can return exit 3 on released 0.10.0 — `counterfactual_fairness_divergence` does not attach caveats until a later toolkit release.

---

## Inputs

### Mode selection

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `csv` | in `fairness-check` | `""` | Path to the data file (CSV or Parquet: `.csv`, `.parquet`, `.pq`), relative to the repository root. Selects `fairness-check` mode. |
| `config` | in `llm-fairness-check` | `""` | Path to an `llm_eval` YAML config, relative to the repository root. Selects `llm-fairness-check` mode. |

### `fairness-check` only

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `y-true` | yes | `""` | Column name for ground-truth labels. |
| `sensitive` | yes | `""` | Sensitive attribute column name(s). Comma-separated for multiple attributes, e.g. `"gender,race"`. |
| `y-pred` | no | `""` | Column name for predicted labels (classification). |
| `score` | no | `""` | Column name for predicted scores (regression / ranking). |

### Both modes

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `metric` | see below | `""` | Metric to gate. In `fairness-check` mode, `demographic_parity_difference` or `equalized_odds_difference`, defaulting to `equalized_odds_difference`. In `llm-fairness-check` mode, an evaluator key your config declares — required whenever `threshold` is set, and with no default, because the tabular default is not a valid LLM evaluator. |
| `threshold` | no | `""` | Fairness threshold for the selected metric. Defaults to `"0.05"` in `fairness-check` mode. In `llm-fairness-check` mode it has no default: leave it unset to report without gating on a number. |
| `fail-on-violation` | no | `"true"` | `"true"` exits 1 when the threshold is exceeded. `"false"` surfaces the result without failing. In `llm-fairness-check` mode this remaps exit 1 only — usage errors (2), illustrative results (3), and undefined results (4) are never remapped. |
| `min-group-size` | no | `""` | Minimum samples per group. Defaults to `30` in `fairness-check` mode. Left unset in `llm-fairness-check` mode so fairpipe's LLM default of `5` applies; `30` would be six times stricter and push small recorded fixtures to `nan`. |
| `with-ci` | no | `"true"` | Compute bootstrap confidence intervals for reported metrics. |
| `fairpipe-version` | no | `"latest"` | fairpipe version to install. Use `"latest"` for the newest release or pin a specific version such as `"0.10.0"`. Needs `0.8.0`+ for `--threshold`/`--metric` in `fairness-check` mode, and `0.10.0`+ for `llm-fairness-check` mode. |

---

## Outputs

| Output | Description |
|--------|-------------|
| `passed` | `"true"` if the selected metric is within threshold, `"false"` otherwise. **Empty string** when there is no boolean answer — an illustrative result, an undefined (insufficient-evidence) result, or a usage error — mirroring fairpipe's `passed=null`. Branch on `gate-status` to tell those apart. |
| `gate-status` | `pass`, `fail`, `illustrative`, `undefined`, or `usage-error`. Mirrors fairpipe's canonical `gate_status`. |
| `exit-code` | Raw exit code from the fairpipe CLI, before `fail-on-violation` is applied: `0` pass, `1` threshold miss, `2` usage error, `3` illustrative, `4` undefined. |
| `mode` | `fairness-check` or `llm-fairness-check`. |
| `metric-value` | Value of the evaluated metric as a string, or `"N/A"`. |
| `dpd` | Demographic parity difference as a string (4 decimal places), or `"N/A"`. Deprecated — use `metric-value`. Always `"N/A"` in `llm-fairness-check` mode. |
| `report-path` | Absolute path to the written markdown report. Empty on a usage error, because fairpipe fails before rendering a report. |

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

      - uses: SvrusIO/fairpipe-action@v2
        with:
          csv: data/predictions.csv
          y-true: y_true
          y-pred: y_pred
          sensitive: gender
          threshold: "0.05"
```

### Classification — multiple sensitive attributes

```yaml
- uses: SvrusIO/fairpipe-action@v2
  with:
    csv: data/predictions.csv
    y-true: y_true
    y-pred: y_pred
    sensitive: "gender,race"
    threshold: "0.10"
```

### Regression — score-based fairness

```yaml
- uses: SvrusIO/fairpipe-action@v2
  with:
    csv: data/scores.csv
    y-true: actual_score
    score: predicted_score
    sensitive: age_group
    threshold: "0.05"
```

### Pin a specific fairpipe version

```yaml
- uses: SvrusIO/fairpipe-action@v2
  with:
    csv: data/predictions.csv
    y-true: y_true
    y-pred: y_pred
    sensitive: gender
    fairpipe-version: "0.8.0"
```

### Audit-only mode — report without failing

```yaml
- uses: SvrusIO/fairpipe-action@v2
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
  uses: SvrusIO/fairpipe-action@v2
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
- uses: SvrusIO/fairpipe-action@v2
  with:
    csv: data/predictions.parquet
    y-true: y_true
    y-pred: y_pred
    sensitive: gender
```

---

## `llm-fairness-check` mode

Set `config` to an `llm_eval` YAML file and the action runs `fairpipe llm-eval` instead of `fairpipe validate`.

```yaml
# .github/workflows/llm-fairness-check.yml
name: LLM Fairness Check
on: [pull_request]

jobs:
  llm-fairness:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: SvrusIO/fairpipe-action@v2
        with:
          config: llm_eval.yml
          metric: "refusal_rate_disparity"
          threshold: "0.25"
          fail-on-violation: "true"
```

### Exit codes

`fairpipe llm-eval` has five meaningful exit codes, and this action keeps them distinct rather than collapsing them into pass/fail. A red check can be decoded without opening the report:

| Exit | `gate-status` | `passed` | Step | Meaning |
|------|---------------|----------|------|---------|
| 0 | `pass` | `"true"` | ✅ passes | Threshold met, or no threshold, on a finite non-caveated metric |
| 1 | `fail` | `"false"` | ❌ fails | Threshold miss on a **non-caveated** gated metric |
| 2 | `usage-error` | `""` | 🚨 fails | Config or environment problem — the eval never completed |
| 3 | `illustrative` | `""` | ⚠️ fails | Gated metric carries a caveat — **even if the number would pass** |
| 4 | `undefined` | `""` | 🚫 fails | Gated metric is non-finite (insufficient evidence; typically `min_group_size`) |

`fail-on-violation: "false"` remaps exit 1 to 0. Usage errors (2), illustrative results (3), and undefined results (4) are never remapped.

### Exit 3 is not a fairness failure

A caveated metric comes from a demo or otherwise non-evidential fixture. fairpipe returns `illustrative` for it even when the value would pass the threshold, so a demo fixture can never be mistaken for a green gate.

The action **fails closed** on exit 3 — but makes it distinguishable, so nobody debugs a fairness regression that isn't one:

- `gate-status` is `illustrative` and `passed` is empty, not `"false"`
- a `::warning` annotation states that this is neither a pass nor a fairness failure, and includes fairpipe's caveat text
- the job summary carries the caveat and the full report

To gate on a real number, point `cache_dir` at a cache whose `manifest.json` does not set `"illustrative": true`.

### Exit 4 is not a pass

When every eligible group falls below `min_group_size` (or fewer than two remain), fairpipe declines to produce a finite disparity number. That used to read as a green gate; it now exits **4** with `gate-status=undefined` and an empty `passed`.

The action **fails closed** on exit 4 — with an annotation naming `min_group_size` as the likely cause — so an undersized audit cannot be mistaken for a clean bill of health.

### Exit 2 covers several causes

fairpipe returns 2 for every usage-class problem, and the code alone cannot say which. The annotation names them all, because the most likely one in CI is a cache miss rather than a typo:

1. **Cache miss in replay-only mode** — `cache_dir` is set but an entry is absent, which happens whenever the prompts, provider, model, or params changed since the cache was recorded.
2. **Live calls blocked by the kill-switch** — a config without `cache_dir` needs `FAIRPIPE_LLM_ALLOW_LIVE=1` and a provider key.
3. **`threshold` without `metric`** — `metric` is required whenever `threshold` is set.
4. **Unknown metric** — not one of the evaluators the config declares.
5. **Missing or invalid config.**

### Replay from a committed cache

Set `cache_dir` in your `llm_eval` config and point it at a committed recorded cache. fairpipe enables replay-only whenever `cache_dir` is present, so a cache miss fails rather than silently calling a provider. That makes the check deterministic, free, and runnable on forks with no secrets.

There is deliberately **no action input for this**: replay is a property of your config, not of the action, and the CLI has no `--cache-dir` flag to forward.

Replay needs no provider SDK, so the action installs plain `fairpipe` for a replay-only job and only adds the `[llm]` extra when live calls are enabled.

### Live provider calls

Live HTTP is **forbidden by default** in fairpipe — that is the safe default, not a workaround. Without the opt-in, a genuine eval fails closed with `LiveLLMCallForbidden` rather than hanging or billing a key by surprise.

A live job must set both the kill-switch and the provider key as `env:` on the step:

```yaml
- uses: SvrusIO/fairpipe-action@v2
  env:
    FAIRPIPE_LLM_ALLOW_LIVE: "1"
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  with:
    config: llm_eval.yml
    metric: "refusal_rate_disparity"
    threshold: "0.25"
    fail-on-violation: "true"
```

Credentials are passed as `env:`, never as inputs — action inputs are echoed in logs and env dumps. fairpipe reads `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` from the environment itself. When the action sees the live opt-in it installs `fairpipe[llm]` for the provider SDKs.

### Consuming the gate status

```yaml
- name: LLM fairness check
  id: llm
  continue-on-error: true
  uses: SvrusIO/fairpipe-action@v2
  with:
    config: llm_eval.yml
    metric: "refusal_rate_disparity"
    threshold: "0.25"

- name: Route on gate status
  run: |
    case "${{ steps.llm.outputs.gate-status }}" in
      pass)         echo "Within threshold." ;;
      fail)         echo "Fairness regression — blocking."; exit 1 ;;
      illustrative) echo "Caveated fixture; not a verdict. Fix the fixture." ; exit 1 ;;
      undefined)    echo "Insufficient evidence (likely min_group_size)."; exit 1 ;;
      usage-error)  echo "Check never ran — see the annotation."; exit 1 ;;
    esac
```

---

## Job Summary

When the action runs, it appends a fairness report to the [GitHub Actions job summary](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#adding-a-job-summary). The summary includes:

- Pass/fail status with the DPD value and threshold
- Full per-group metric table from `fairpipe validate`
- Bootstrap confidence intervals (when `with-ci: "true"`)

---

## How It Works

1. **Resolve the mode** from whether `config` or `csv` is set, and reject an ambiguous or incomplete combination.
2. **Set up Python 3.11** using `actions/setup-python@v5`.
3. **Install fairpipe** — the latest release or a pinned version. In `llm-fairness-check` mode the `[llm]` extra is added only when live calls are enabled, and the installed version is checked against the `0.10.0` floor.
4. **Run the CLI** — `fairpipe validate` or `fairpipe llm-eval`, built from inputs with no shell injection risk: all inputs are passed via environment variables and expanded into a bash array.
5. **Annotate** — a `::warning` for an illustrative result, a `::error` for undefined (exit 4 / `min_group_size`) or naming the possible causes of a usage error.
6. **Write the job summary** with the status, the gate status, any caveats, and the full report.
7. **Set step outputs** (`passed`, `gate-status`, `exit-code`, `mode`, `metric-value`, `dpd`, `report-path`).
8. **Exit** — `fail-on-violation: "true"` propagates a threshold miss. In `llm-fairness-check` mode the CLI's exit code is preserved, so usage (2), illustrative (3), and undefined (4) stay distinct and are never remapped.

---

## Requirements

- Runs on any `ubuntu-*` or `macos-*` runner (Python 3.11 is installed by the action).
- `fairness-check` mode: your repository must contain a data file (CSV or Parquet) with prediction and label columns.
- `llm-fairness-check` mode: an `llm_eval` YAML config, fairpipe `0.10.0`+, and either a committed `cache_dir` for replay or the live opt-in described above.

---

## Version compatibility

The examples here use `@v2` (llm-fairness-check mode, merge `b629800`). Use `@v1` only if you want the last pre-mode release (`68c2bb7` — tabular `metric` / `metric-value`, no LLM mode). `@v1.0.0` remains an immutable pin of the original composite action at `d8fe950`.

---

## License

Apache 2.0 — see [LICENSE](LICENSE).

---

*Powered by [fairpipe](https://github.com/JobCollins/fairness_pipeline_dev_toolkit)*
