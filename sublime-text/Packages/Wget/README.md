# Sublime Wget

A plugin for Sublime Text 3 that retrieves the contents of a URL for you, runs the contents through an html-to-markdown parser, and displays the result in a new tab in Sublime

## Installation

1. **Recommended:** Download [Package Control](http://wbond.net/sublime_packages/package_control) and install using the *Package Control: Install Package* command (search for *Wget*)
2. **Not recommended:** Simply download this repo and save it to a *Wget* directory inside your Sublime Packages/ directory. You will not receive automatic updates as you would following option 1

## Usage 

There are two basic use-cases:

1. Ad-hoc retrieval of web pages
2. Retrieval of web pages from a user-defined list

### 1. Ad-hoc retrieval of web pages

SublimeWget adds a new command to your palette: *'Wget'*. Simply select this command, type in the url you want to access and press enter. Don't worry about adding 'http://' at the start, SublimeWget will add it if it's missing. 'www' is not required either.

SublimeWget will retrieve the page asynchronously, and will open the page in a new tab in Sublime when done.

### 2. Retrieval of web pages from a user-defined list

Navigate to *Preferences* > *Package Settings* > *SublimeWget* > *Settings - User*

In this file, add the following, and customise your `sites` list as desired (obviously, uncomment the site object to get started)

```json
{
  "sites": [
    // {
    //   "name":"", //Appears as filename in window e.g. "Bootstrap CSS"
    //   "address":"" //The website to load e.g. "http://getbootstrap.com/css"
    // }
  ]
}
```

SublimeWget has added a new command to your palette to access this list of sites quickly: *'Wget: My Sites'*. Choose this command from the command palette and SublimeWget will present a list of your sites to choose from.

SublimeWget will retrieve the page asynchronously, and will open the page in a new tab in Sublime when done.

## License

Copyright (c) 2014 James Hill <oblongmana@gmail.com>

Html2text.py is Copyright (c) 2004-2008 Aaron Swartz (GPLv3)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


*P.S. If you happen to find any deficiencies in attribution or license details anywhere in here, please do email me or post an issue*
