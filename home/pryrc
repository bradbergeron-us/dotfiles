# ~/.pryrc — Pry REPL configuration
# Pry is an enhanced Ruby REPL with syntax highlighting, source browsing,
# and a plugin ecosystem. Used as the default Rails console in many setups.
# Install: gem install pry pry-byebug pry-rails

# Colour and editor
Pry.config.color  = true
Pry.config.editor = ENV.fetch('EDITOR', 'vim')

# Shorter prompt: `[1] pry> ` instead of `[1] pry(main)> `
Pry.config.prompt_name = 'pry'

# Aliases — feel like the shell
Pry.commands.alias_command 'q',  'exit'
Pry.commands.alias_command 'e',  'exit'
Pry.commands.alias_command 'c',  'continue' rescue nil  # needs pry-byebug
Pry.commands.alias_command 'n',  'next'     rescue nil
Pry.commands.alias_command 's',  'step'     rescue nil

# Pager — use bat for syntax-highlighted output if available
if system('command -v bat > /dev/null 2>&1')
  Pry.config.pager = true
end

# History
Pry.config.history_save = true
Pry.config.history_file = File.expand_path('~/.pry_history')
