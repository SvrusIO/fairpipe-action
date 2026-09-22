# Changelog

All notable changes to [SvrusIO/fairpipe-action](https://github.com/SvrusIO/fairpipe-action) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added

- **`undefined` gate status (exit 4):** maps fairpipe's non-finite / insufficient-evidence
  result (typically `min_group_size`) to `gate-status=undefined` with empty `passed`, a
  `::error` annotation naming the guard, and a job-summary caution. Without this mapping,
  exit 4 would fall through the Action's unknown-exit fallback to `usage-error`.
- Offline CI job `test-llm-undefined` (clean fixture + `min-group-size: "30"` → exit 4).
  Temporarily pins that job alone to unreleased fairpipe via `FAIRPIPE_PIP_SPEC` (git
  install from `SvrusIO/fAIr` at Wave 1 merge SHA
  `66d3cf1ebe2aff78f5db0231a66b732ada7e8563` — was the Wave 1c branch; SHA so branch
  deletion is safe). Remove when exit 4 is on PyPI ([#3](https://github.com/SvrusIO/fairpipe-action/issues/3)).
  Other LLM jobs stay on PyPI `latest`.

### Changed

- `fail-on-violation: "false"` still remaps exit 1 only; exit 4 is never remapped.
- Docs / outputs enumerate `undefined` alongside `pass` / `fail` / `illustrative` /
  `usage-error`. Additive for callers that only handle 0–3; exhaustive `gate-status`
  switches need a new arm.

### Known issues

- **Interim mislabel on `@v2`:** until a fairpipe release emits exit 4 *and* this Action
  patch is what callers run (moved `@v2` tag or a `v3`), anyone using a pre-release
  fairpipe through the current `@v2` composite still maps unknown exit 4 → `usage-error`.
  The failure is real; the label is wrong. Patched Action `main` labels it `undefined`.

## [v2] — 2026-09-18

Tagged at merge commit `b629800` (PR [#2](https://github.com/SvrusIO/fairpipe-action/pull/2)).

### Added

- **`llm-fairness-check` mode:** when `config:` is set, the action runs `fairpipe llm-eval` instead of `fairpipe validate`. Mode is inferred from `config` vs `csv` (mutually exclusive).
- **Outputs:** `gate-status` (`pass` / `fail` / `illustrative` / `usage-error`), `exit-code`, and `mode`, alongside existing `passed` / `metric-value` / `dpd` / `report-path`.
- **Exit codes 0 / 1 / 2 / 3** preserved from `fairpipe llm-eval`. Exit 3 fails closed with a distinguishable `::warning` and step-summary caveat; exit 2 emits `::error` naming overloaded causes (cache miss / kill-switch / threshold-without-metric / etc.).
- **Offline CI** for LLM gates via `tests/make_llm_fixture.py` (pass, threshold miss, illustrative, usage-error, mode selection, pre-0.10.0 pin rejection).

### Changed

- Tabular defaults for `metric` / `threshold` / `min-group-size` move into the fairness-check step so LLM mode can leave them unset (`min-group-size` falls through to fairpipe's LLM default of 5).
- Score-only runs default `metric` to `mae_parity_difference`; classification defaults remain `equalized_odds_difference`.
- Install uses bare `fairpipe` for replay-only LLM jobs; adds `[llm]` only when live calls are opted in (`FAIRPIPE_LLM_ALLOW_LIVE` / `FAIRPIPE_LLM_FORBID_LIVE=0`).
- LLM mode enforces fairpipe **≥ 0.10.0**. Tabular `--threshold` / `--metric` require fairpipe **≥ 0.8.0** (not 0.7.3).
- `test-pinned-version` pins `0.8.0` (first release with `--threshold` / `--metric`).
- Docs and examples use `@v2`. `@v1` was force-moved to `68c2bb7` (last pre-mode release). `@v1.0.0` stays at `d8fe950` as an immutable point-in-time tag.

### Known issues

- Tabular metric parsing still uses `grep -oP` (GNU-only). See [#1](https://github.com/SvrusIO/fairpipe-action/issues/1). Not fixed in v2.

---

## [v1] — 2026-05-14

Force-moved tag tip: `68c2bb7` — `metric` input and `metric-value` output; threshold delegated to the CLI.

## [v1.0.0] — 2026-05-07

Immutable tag at `d8fe950` — initial composite action (`fairpipe validate` only).
