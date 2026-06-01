# ~/.irbrc — IRB (Interactive Ruby) configuration
# Applies to `irb` and `rails console` (which uses IRB under the hood).

require 'irb/completion'  # tab completion for methods and constants

# Persistent history across sessions
IRB.conf[:SAVE_HISTORY] = 2000
IRB.conf[:HISTORY_FILE]  = "#{Dir.home}/.irb_history"

# Quality-of-life settings
IRB.conf[:AUTO_INDENT]  = true   # auto-indent multi-line expressions
IRB.conf[:USE_COLORIZE] = true   # syntax-highlighted output (IRB 1.3+)
IRB.conf[:PROMPT_MODE]  = :SIMPLE  # cleaner prompt: >> instead of irb(main):001:0>

# Shorter aliases for frequent operations
# `q` to exit without typing `exit` or `quit`
if defined?(IRB::Context)
  IRB::Context.class_eval do
    alias_method :q, :exit
  end
end
