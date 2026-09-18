# Changelog

All notable changes to [SvrusIO/fairpipe-action](https://github.com/SvrusIO/fairpipe-action) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

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
