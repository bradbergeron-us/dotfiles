Dotfiles 
=========

###First Time Setup See -> [Setup Guide](https://github.com/bradbergeron-us/dotfiles/blob/master/setup.md)
> Uses Rakefile to delegate tasks including installing all dependencies [Homebrew, rbenv, pow, npm, prezto fork etc.]

Great if you are starting from scratch and have nothing installed the rake tasks can automate that process.

### My Preferred method -> Idempotent `$ ./install` script
> Installs Symlinks
After cloning this repo, run `$ ./install` to automatically set up the development environment. Note that the install script is idempotent: it can safely be run multiple times.

This Dotfiles Repository uses [Dotbot](https://github.com/anishathalye/dotbot) for installation.

Afteradding dotbot for streamlining symlinking dotfiles. I used to rely heavily on Rake but the Rakefile is not optimized to be re-used like [Dotbot](https://github.com/anishathalye/dotbot). Rake offers a multitude of tasks/multitasks but it is easier for me to just clone the repo and `$ ./install` which has helped me keep both of my Macs in synchronization and optimized for development.

A small bit of frusteration I had when configuring Dotbot was dealing with white-case significant YAML files... for that reason I may rewrite the script in JSON which is another valid format for Dotbot that I may rewrite in at some point. But after the frustration of configuring the YAML file it works, just watch out for that whitespace!

The reward for maintaing a organized dotfile repository is being in sync with your custom settings wherever you are just a git clone and `$ ./install` command away from development bliss.

Troubleshooting Prezto Install
------------------------------
On occassion the Prezto configuration can load but not be linked properly.
Just copy and paste this snippet if you do have a problem loading the shell theme.


        setopt EXTENDED_GLOB
        for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
          ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
        done


Making Local Customizations
---------------------------

You can make local customizations for some programs by editing these files:

* `vim` : `~/.vimrc_local`
* `zsh` : `~/.zshrc_local_before` run before `.zshrc`
* `zsh` : `~/.zshrc_local_after` run after `.zshrc`
* `git` : `~/.gitconfig_local`
* `hg` : `~/.hgrc_local`
* `tmux` : `~/.tmux_local.conf`

What's it Look Like?
---------------------------
![Mac-Vim](https://s3.amazonaws.com/f.cl.ly/items/3F343Q0H3q0e2x3U3x1l/Image%202015-06-02%20at%204.30.02%20AM.png "Mac-Vim Setup")

### Welcome to Gotham City

![Terminal-Vim] (https://s3.amazonaws.com/f.cl.ly/items/3j1s1M23230L3G201Q3s/Image%202015-06-02%20at%204.39.48%20AM.png "Terminal-Vim")

Heres What else I have Stashed So Far
-------------------------------------------------------------
- ZSH Shell with Pure Theme
- Prezto Fork (Perfect for OSX users)
- Git Custom Aliases
- Ag (Ack interchangeable)
- Homebrew
- iTerm2 (colors)
- Tmux configuration
- OS X Settings
- rbenv
- Sublime Text
- Vim
- Ultisnips


Inspirational Dotfiles
----------------------

1. [drewbarontini/dotfiles](https://github.com/drewbarontini/dotfiles)

2. [nicknisi/dotfiles](https://github.com/nicknisi/dotfiles)

3. [josemota/dotfiles](https://github.com/josemota/dotfiles)

4. [Wistia/whim](https://github.com/wistia/whim)

5. [skwp/dotfiles](https://github.com/skwp/dotfiles)
