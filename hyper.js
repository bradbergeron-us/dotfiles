"use strict";
// Future versions of Hyper may add additional config options,
// which will not automatically be merged into this file.
// See https://hyper.is#cfg for all currently supported options.
module.exports = {
    config: {
        fontSize: 14,
        fontFamily: 'JetBrainsMono Nerd Font, Menlo, monospace',
        fontWeight: 'normal',
        fontWeightBold: 'bold',
        lineHeight: 1.25,
        letterSpacing: 0.2,
        cursorColor: 'rgba(255,255,255,0.9)',
        cursorAccentColor: '#000000',
        cursorShape: 'BLOCK',
        cursorBlink: true,
        foregroundColor: '#c0caf5',
        backgroundColor: '#1a1b26',
        selectionColor: 'rgba(147,197,253,0.3)',
        borderColor: '#3d59a1',
        padding: '10px 14px',
        shell: '/bin/zsh',
        shellArgs: ['--login'],
        bell: false,
        disableLigatures: false,
        webGLRenderer: false,
        preserveCWD: true,
        showWindowControls: true,
        activeTab: '💼',
      },
    // a list of plugins to fetch and install from npm
    // format: [@org/]project[#version]
    // examples:
    plugins: [
        "hyper-pane",              // For splitting panes with keyboard shortcuts
        "hyper-search",            // Ctrl+F in terminal scrollback
        "hypercwd",                // Start in same folder for new tabs
        "hyper-font-ligatures",    // Enable font ligatures
        // "hyper-active-tab",     // Disabled - conflicts with zsh title management
        "hyperline",               // Status bar showing CPU/mem
        "hyper-tokyo-night"        // Tokyo Night theme
    ],
    // in development, you can create a directory under
    // `~/.hyper_plugins/local/` and include it here
    // to load it and avoid it being `npm install`ed
    localPlugins: [],
    keymaps: {
    // Example
    // 'window:devtools': 'cmd+alt+o',
    },
};
//# sourceMappingURL=config-default.js.map