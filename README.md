Dotfiles 
=========

>###Follow the [setup guide](https://github.com/bradbergeron-us/Dotfiles-Relief/wiki/Setup-for-Installation) to install.


TODO:
--------
1. Fix setup/zsh script needs some work still some cleaning up
2. The Symlinks in Rake are not the cleanest.
3. Would like to be able to add in more edge cases to the rake tasks to not have to edit the `Rakefile` on the fly
4. More to come... (This is a life's work, but will continue to change and evolve)
5. In the process of moving all of my development onto Docker Containers so Having a great way to get custom settings for text editors is a HUGE convenience along with isolating your environment for development.
6. Expect more to come for Rsync to remote servers; Chef & Puppet Scripts for automation and provisioning of Docker images.
7. Feel free to send a pull request if you have any good ideas on provisioning servers, docker images and so on...


###Yes ZSH Setup requires additional steps
Here is a quick script to hook into your new Shell:

### Must Do this to Hook up Zsh Properly
  1. Launch Zsh:
```sh
        zsh
```
  2. Clone the repository:
```sh
       git clone --recursive https://github.com/bradbergeron-us/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
```
  3. Create a new Zsh configuration by copying the Zsh configuration files
     provided:
```
        setopt EXTENDED_GLOB
        for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
          ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
        done
```

  4. Set Zsh as your default shell:
```sh
        chsh -s /bin/zsh
```
  5. Open a new Zsh terminal window or tab.



###What's it Look Like?
![Mac-Vim](https://s3.amazonaws.com/f.cl.ly/items/3F343Q0H3q0e2x3U3x1l/Image%202015-06-02%20at%204.30.02%20AM.png "Mac-Vim Setup")




### Like Gotham City

![Terminal-Vim] (https://s3.amazonaws.com/f.cl.ly/items/3j1s1M23230L3G201Q3s/Image%202015-06-02%20at%204.39.48%20AM.png "Terminal-Vim")

Heres What else I have Stashed and Still a Work in Progress?
-------------------------------------------------------------
- Git
- Bash
- Ag (Ack interchangeable)
- Homebrew
- iTerm2 (colors)
- tmux configuration
- OS X Settings
- rbenv
- Sublime Text
- Vim



Inspirational Dotfiles
----------------------

1. [drewbarontini/dotfiles](https://github.com/drewbarontini/dotfiles)

2. [nicknisi/dotfiles](https://github.com/nicknisi/dotfiles)

3. [josemota/dotfiles](https://github.com/josemota/dotfiles)

4. [Wistia/whim](https://github.com/wistia/whim)

5. [skwp/dotfiles](https://github.com/skwp/dotfiles)
