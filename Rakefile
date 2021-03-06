# ====================================
#   Variables
# ====================================

# ----- Original Locations ----- #

original_locations                          = {}
original_locations[:ackrc]                  = "#{ ENV['HOME'] }/.dotfiles/ack/ackrc"
original_locations[:agignore]               = "#{ ENV['HOME'] }/.dotfiles/ag/agignore"
original_locations[:applescripts_directory] = "#{ ENV['HOME'] }/.dotfiles/applescripts"
original_locations[:bin_directory]          = "#{ ENV['HOME'] }/.dotfiles/bin"
original_locations[:ctags]                  = "#{ ENV['HOME'] }/.dotfiles/ctags/ctags"
original_locations[:git_directory]          = "#{ ENV['HOME'] }/.dotfiles/git"
original_locations[:gitconfig]              = "#{ ENV['HOME'] }/.dotfiles/git/gitconfig"
original_locations[:gitignore]              = "#{ ENV['HOME'] }/.dotfiles/git/gitignore"
original_locations[:gvimrc]                 = "#{ ENV['HOME'] }/.dotfiles/vim/gvimrc"
original_locations[:hooks_directory]        = "#{ ENV['HOME'] }/.dotfiles/git/hooks"
original_locations[:irb_directory]          = "#{ ENV['HOME'] }/.dotfiles/irb"
original_locations[:jshintrc]               = "#{ ENV['HOME'] }/.dotfiles/jshintrc"
original_locations[:jscsrcrc]               = "#{ ENV['HOME'] }/.dotfiles/jscrc"
original_locations[:mongorc]                = "#{ ENV['HOME'] }/.dotfiles/mongorc"
original_locations[:nginx_directory]        = "#{ ENV['HOME'] }/.dotfiles/nginx"
original_locations[:prezto_directory]       = "#{ ENV['HOME'] }/.dotfiles/prezto"
original_locations[:psqlrc]                 = "#{ ENV['HOME'] }/.dotfiles/psqlrc"
original_locations[:ruby_directory]         = "#{ ENV['HOME'] }/.dotfiles/ruby"
original_locations[:rspec]                  = "#{ ENV['HOME'] }/.dotfiles/rspec/rspec"
original_locations[:template_directory]     = "#{ ENV['HOME'] }/.dotfiles/git/templates"
original_locations[:tmux_directory]         = "#{ ENV['HOME'] }/.dotfiles/tmux"
original_locations[:"tmux.conf"]            = "#{ ENV['HOME'] }/.dotfiles/tmux/tmux.conf"
original_locations[:vim]                    = "#{ ENV['HOME'] }/.dotfiles/vim"
original_locations[:vimrc]                  = "#{ ENV['HOME'] }/.dotfiles/vim/vimrc"



# ----- New Locations ----- #

new_locations                           = {}
new_locations[:ackrc]                   = "#{ ENV['HOME'] }/.ackrc"
new_locations[:agignore]                = "#{ ENV['HOME'] }/.agignore"
new_locations[:applescripts_directory]  = "#{ ENV['HOME'] }/.applescripts"
new_locations[:bin_directory]           = "#{ ENV['HOME'] }/.bin"
new_locations[:ctags]                   = "#{ ENV['HOME'] }/.ctags"
new_locations[:git_directory]           = "#{ ENV['HOME'] }/.git"
new_locations[:gitconfig]               = "#{ ENV['HOME'] }/.gitconfig"
new_locations[:gitignore]               = "#{ ENV['HOME'] }/.gitignore"
new_locations[:gvimrc]                  = "#{ ENV['HOME'] }/.gvimrc"
new_locations[:hooks_directory]         = "#{ ENV['HOME'] }/.git/hooks"
new_locations[:irb_directory]           = "#{ ENV['HOME'] }/.irb"
new_locations[:jshintrc]                = "#{ ENV['HOME'] }/.jshintrc"
new_locations[:jscrc]                   = "#{ ENV['HOME'] }/.jscrc"
new_locations[:mongorc]                 = "#{ ENV['HOME'] }/.mongorc"
new_locations[:nginx_directory]         = "#{ ENV['HOME'] }/.nginx"
new_locations[:prezto_directory]        = "#{ ENV['HOME'] }/.zprezto"
new_locations[:psqlrc]                  = "#{ ENV['HOME'] }/.psqlrc"
new_locations[:rspec]                   = "#{ ENV['HOME'] }/.rspec"
new_locations[:ruby_directory]          = "#{ ENV['HOME'] }/.ruby"
new_locations[:templates_directory]     = "#{ ENV['HOME'] }/.git/templates"
new_locations[:ruby_directory]          = "#{ ENV['HOME'] }/.ruby"
new_locations[:tmux_directory]          = "#{ ENV['HOME'] }/.tmux"
new_locations[:tmux_directory]          = "#{ ENV['HOME'] }/.tmux.conf"
new_locations[:vim]                     = "#{ ENV['HOME'] }/.vim"
new_locations[:vimrc]                   = "#{ ENV['HOME'] }/.vimrc"




# ----- Installation Order ----- #

current_step = 0

installation_order = [
  'install_npm_packages',
  'install_zsh',
  'install_vim',
  'install_rbenv',
  'install_gems',
  'install_homebrew',
  'install_homebrew_packages',
  'install_osx_settings',
  'install_sublime_text_settings',
  'install_pow',
  'install_symlinks',
  'install_cleanup'
]

# ====================================
#   Installation Start
# ====================================

task :install do
  puts '---------------------------------------------'
  puts ' bradbergeron-us/dotfiles Installation'
  puts " --> Type 'start'"
  puts '---------------------------------------------'

  run installation_order[current_step] if response?('start')
end

# ====================================
#   Install Symlinks
# ====================================

task :install_symlinks, :run do |task, args|
  current_step = current_step + 1

  prompt 'symlinks'

  if response?('y')
    message 'Symlinking files...'

    create_symlinks(original_locations, new_locations)

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install Vim
# ====================================

task :install_vim, :run do |task, args|
  current_step = current_step + 1

  prompt 'Vim'

  if response?('y')
    message 'Installing Vundle...'

    vundle_directory = "#{ ENV['HOME'] }/.vim/bundle/vundle"

    unless File.exists?(vundle_directory)
      system "git clone https://github.com/gmarik/vundle.git #{ vundle_directory }"
      puts "Done! Run ':BundleInstall' in Vim to install plugins."
    else
      puts "#{ vundle_directory } already exists. Contining.."
    end

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install ZSH Configuration
# ====================================

task :install_zsh, :run do |task, args|
  current_step = current_step + 1

  prompt 'ZSH with Prezto Configurations & Pure Theme'

  if response?('y')
    message 'Installing personalized Prezto Fork ...'

    system 'bash setup/zsh'
     sh "ln -s ~/.zprezto/runcoms/.zlogin"
     sh "ln -s ~/.zprezto/runcoms/.zpreztorc"
     sh "ln -s ~/.zprezto/runcoms/.zshrc"
     sh "ln -s ~/.zprezto/runcoms/.zshenv"
     sh "ln -s ~/.zprezto/runcoms/.zprofile"
     sh "echo 'Symlinked ~/.zprezto modules and runcoms!')"
     sh "chsh -s /bin/zsh"
     sh "echo 'Prezto! Zsh has been configured'"
done

chsh -s /bin/zsh
echo 'Changed Shell to ZSH'

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install rbenv
# ====================================

task :install_rbenv, :run do |task, args|
  current_step = current_step + 1

  prompt 'rbenv'

  if response?('y')
    message 'Installing rbenv...'

    system 'bash setup/rbenv'

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install Homebrew
# ====================================

task :install_homebrew, :run do |task, args|
  current_step = current_step + 1

  prompt 'Homebrew'

  if response?('y')
    message 'Installing Homebrew...'

    system 'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install Homebrew Packages
# ====================================

task :install_homebrew_packages, :run do |task, args|
  current_step = current_step + 1

  prompt 'Homebrew Packages'

  if response?('y')
    message 'Installing Homebrew Packages...'

    system 'bash setup/brew'

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install NPM Packages
# ====================================

task :install_npm_packages, :run do |task, args|
  current_step = current_step + 1

  prompt 'NPM Packages'

  if response?('y')
    message 'Installing NPM Packages...'

    system 'bash setup/npm'

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install Gems
# ====================================

task :install_gems, :run do |task, args|
  current_step = current_step + 1

  prompt 'Ruby Gems'

  if response?('y')
    message 'Installing Ruby Gems...'

    system 'bash setup/gems'

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install OS X Settings
# ====================================

task :install_osx_settings, :run do |task, args|
  current_step = current_step + 1

  prompt 'OS X Settings'

  if response?('y')
    message 'Installing OS X Settings...'

    system 'bash setup/osx'

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install Sublime Text Settings
# ====================================

 task :install_sublime_text_settings, :run do |task, args|
   current_step = current_step + 1

   prompt 'Sublime Text Settings'

   if response?('y')
     message 'Installing Sublime Text Settings...'

     system 'bash setup/sublime'
     system 'defaults write com.sublimetext.2 ApplePressAndHoldEnabled -bool false'

     message "Now, install Package Control. Type 'next' when you are ready."

     if response?('next')
        run installation_order[current_step] unless args[:run] == 'single'
     end
   end
 end

# ====================================
#   Install Pow
# ====================================

task :install_pow, :run do |task, args|
  current_step = current_step + 1

  prompt 'Pow'

  if response?('y')
    message 'Installing Pow...'

    system 'curl get.pow.cx | sh'

    run installation_order[current_step] unless args[:run] == 'single'
  end
end

# ====================================
#   Install Cleanup
# ====================================

task :install_cleanup do
  system "source #{ ENV['HOME'] }/.zshrc"
  puts "Done! Run 'open ~/.dotfiles' to see your new files."
end

# ====================================
#   Install Command Line Tools
# ====================================

task :install_command_line_tools do
  prompt 'Command Line Tools'

  if response?('y')
    message 'Installing Command Line Tools...'

    system 'xcode-select --install'
  end
end

# # Prints out a message to the console
# #
# == Parameters
#
# @param string [String] the string to print out
#
# == Usage
#
#   message 'This is a message to show.'
#
def message(string)
  puts
  puts "--> #{ string }"
end

# Prints out a message prompt for the user
#
# == Parameters
#
# @param section [String] the section to ask about
#
# == Usage
#
# prompt 'Command Line Tools'

def prompt(section)
  puts
  puts '---------------------------------------------'
  puts " Ready to install #{ section }? [y|n]"
  puts '---------------------------------------------'
end

# Determines the user's response
#
# == Parameters
#
# @param value [String] the response that is expected
#
# == Usage
#
#   if response?('yes')
#     # ...
#   end
#
def response?(value)
  STDIN.gets.chomp == value ? true : false
end

# Runs a particular Rake task
#
# == Parameters
#
# @param task [String] the task to run
#
# == Usage
#
#   run 'install_homebrew'
#
def run(task)
  Rake::Task[task].invoke
end

# Determines if a symlink can be made
#
# == Parameters
#
# @param destination_path [String] the destination of the symlink
#
# == Usage
#
#   if can_symlink?(destination_path)
#     # ...
#   end
#
def can_symlink?(destination_path)
  File.exists?(destination_path) ? false : true
end

# Creates all of the specified symlinks
#
# == Parameters
#
# @param original_locations [Hash] set of original locations
# @param new_locations [Hash] set of new locations
#
# == Usage
#
#   create_symlinks(original_locations, new_locations)
#
def create_symlinks(original_locations, new_locations)
  (0..original_locations.count - 1).each do |index|
    old = original_locations[ original_locations.keys[index] ]
    new = new_locations[ new_locations.keys[index] ]

    if can_symlink?(new)
      File.symlink(old, new)
      puts "#{ old } -> #{ new } symlink created."
    else
      puts "#{ new } already exists. Continuing..."
    end
  end
end
