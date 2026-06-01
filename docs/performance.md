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

## Measuring startup time

```sh
# Average of 5 runs
for i in $(seq 1 5); do /usr/bin/time zsh -i -c exit 2>&1; done
```

Or with `hyperfine` (install via `brew install hyperfine`):
```sh
hyperfine --warmup 3 'zsh -i -c exit'
```
