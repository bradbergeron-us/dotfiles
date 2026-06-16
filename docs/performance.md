# Shell Performance

Shell startup time was reduced from ~2.37s to ~0.08s — a 97% improvement — through a series of targeted changes.

---

## What changed

**Replaced chruby + nvm with mise** — the biggest win. The previous setup sourced two chruby scripts, ran `brew --prefix` at startup, and used lazy-loader stub functions for `nvm`/`node`/`npm`/`npx` to avoid nvm's ~500ms cold start. All of that is now one line: `eval "$(mise activate zsh)"`, which adds ~5ms and handles Ruby, Node, Python, Java, and Go with automatic per-project version switching.

**Removed dynamic PATH calls** — a `$(ruby -e 'puts Gem.bindir')` subshell that spawned a full Ruby process on every new shell has been removed.

**Starship Ruby module disabled** — starship's Ruby module executed Ruby on every prompt render, causing intermittent timeout warnings. Disabled in `config/starship.toml`; `command_timeout = 2000` is set as a safety net for other modules.

**Cached `compinit`** — zsh rebuilds its completion dump (`~/.zcompdump`) on every shell start by default. A 24-hour freshness check now skips the rebuild (`compinit -C`) unless the dump is older than a day. Saves ~30–50ms per shell start with no visible downside.

---

## Benchmark (MacBook Pro, Apple Silicon)

| Measurement | Time |
|-------------|------|
| Original (chruby + nvm + Starship Ruby warnings) | ~2.37s |
| After lazy NVM + removing Ruby PATH call | ~0.58s |
| After replacing chruby + nvm with mise | ~0.11s |
| After compinit caching | **~0.08s** |
| **Total improvement** | **~97% faster** |

---

## Optimization methodology

Every change above came from the same loop. Use it whenever startup feels slow
again (a new plugin, a heavy `eval` in `~/.zshrc.local`, etc.):

1. **Measure a baseline** — get a repeatable number before touching anything
   (see [Measuring startup time](#measuring-startup-time)). Always compare
   against the same machine and an otherwise-idle system.
2. **Profile to find the cost** — don't guess. Use `zprof` (below) to rank what
   actually consumes time during an interactive start.
3. **Attack the biggest cost first**, using one of three levers in order of
   preference:
     - **Eliminate** — remove work that runs on *every* shell. The single
       biggest win here was deleting a `$(ruby -e 'puts Gem.bindir')` subshell
       that spawned a full Ruby process per shell.
     - **Replace** — swap a slow tool for a faster one. chruby + nvm (two sourced
       scripts, a `brew --prefix` call, and nvm lazy-loaders) became one line:
       `eval "$(mise activate zsh)"`.
     - **Cache / defer** — pay a cost once and reuse it, or push it to first use.
       `compinit -C` skips rebuilding `~/.zcompdump` unless it is older than a
       day; disabling starship's Ruby module avoids running Ruby on every prompt.
4. **Re-measure** — confirm the change helped and didn't regress correctness
   (completions still work, runtimes still switch per project).
5. **Repeat** until the next-biggest cost isn't worth chasing.

!!! tip "Keep machine-specific weight out of the tracked rc"
    Slow, machine-only setup (corporate tooling, one-off `eval`s) belongs in
    `~/.zshrc.local`, not the tracked `home/zshrc`. That keeps the shared
    baseline fast for every profile and machine.

## Measuring startup time

Time a full interactive start, averaged over several runs:

```sh
# Average of 5 runs
for i in $(seq 1 5); do /usr/bin/time zsh -i -c exit 2>&1; done
```

For a tighter, statistically warmed-up number, use `hyperfine`
(`brew install hyperfine`):

```sh
hyperfine --warmup 3 'zsh -i -c exit'
```

### Profiling with `zprof`

Timing tells you *how slow*; `zprof` (a zsh builtin module) tells you *what* is
slow. Enable it at the very top of your rc, start a shell, then read the report:

```sh
# Temporarily add as the FIRST line of ~/.zshrc (or ~/.zshrc.local):
zmodload zsh/zprof
# ...rest of your rc...

# Then open a new shell and run:
zprof   # prints functions ranked by cumulative time
```

The top entries are where to focus step 3 above. Remove the `zmodload` line once
you're done. For a line-by-line view of what runs at startup, you can also trace
it:

```sh
zsh -i -x -c exit 2>&1 | less   # every command sourced during an interactive start
```

The runtime manager (`mise`) and plugin manager (`sheldon`) are the two heaviest
startup contributors by design — see the [Glossary](glossary.md#mise) for what
each does and the [Architecture](architecture.md) page for how they're wired in.
