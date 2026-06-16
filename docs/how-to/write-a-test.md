# Write a test

The shell helpers are unit-tested with [bats](https://github.com/bats-core/bats-core). Tests live in [`scripts/tests/`](https://github.com/bradbergeron-us/dotfiles/tree/main/scripts/tests) as `*.bats` files and run in CI. `bats-core` ships in the core `Brewfile`.

## 1. Create a test file

Add `scripts/tests/test_<thing>.bats`. Start by loading the shared helper, which resolves `$LIB_DIR`, `$SCRIPTS_DIR`, and `$REPO_ROOT` so tests don't recompute paths:

```bash
#!/usr/bin/env bats
# test_my_helpers.bats — unit tests for scripts/lib/my_helpers.sh
# Run: bats scripts/tests/test_my_helpers.bats

load 'test_helper'

setup() {
  # shellcheck source=/dev/null
  source "$LIB_DIR/my_helpers.sh"
}
```

`setup()` runs before every `@test`. Source the library under test there so each case starts clean.

## 2. Add `@test` blocks

Each test is a `@test "name" { ... }` block. A non-zero exit fails the test; use `run <cmd>` to capture `$status` and `$output` without aborting:

```bash
@test "my_func: returns the trimmed value" {
  result="$(my_func '  hi  ')"
  [ "$result" = "hi" ]
}

@test "my_func: rejects empty input" {
  run my_func ""
  [ "$status" -ne 0 ]
}
```

bats gives each test a scratch dir at `$BATS_TEST_TMPDIR` (auto-created, auto-removed) — use it for fixtures instead of `mktemp`:

```bash
@test "reads a config file" {
  printf 'KEY=value\n' > "$BATS_TEST_TMPDIR/conf"
  [ "$(read_kv_value "$BATS_TEST_TMPDIR/conf" KEY)" = "value" ]
}
```

See [`test_profile_helpers.bats`](https://github.com/bradbergeron-us/dotfiles/blob/main/scripts/tests/test_profile_helpers.bats) for a complete, idiomatic example.

## 3. Run the suite

Run a single file, or the whole directory (what CI does):

```sh
bats scripts/tests/test_my_helpers.bats   # one file
bats scripts/tests/                        # full suite
```

## 4. Commit

```sh
git -C ~/dotfiles add scripts/tests/test_my_helpers.bats
git -C ~/dotfiles commit -m "test: cover my_helpers.sh"
```

!!! tip
    Keep library helpers side-effect-free (no `exit`, no traps, configuration via globals/arguments) — that's what makes them unit-testable. Mirror the patterns in the existing `scripts/lib/*.sh` files.
