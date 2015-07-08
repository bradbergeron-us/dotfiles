"""SublimeWget: In Sublime Text 3, retrieve a web page, turn it into markdown, and display in Sublime"""
__version__ = "1.1.1"
__author__ = "James Hill (oblongmana@gmail.com)"
__copyright__ = "SublimeWget: (C) 2014 James Hill. GNU GPL 3."
__credits__ = ["html2text.py: (C) 2004-2008 Aaron Swartz. GNU GPL 3."]
# P.S. I am not completely up with how to properly credit other GPLv3 licenses. All original license docs have been preserved however, and I've tried to credit appropriately above! Feel free to email me if you'd like any notices tweaked.

import sublime, sublime_plugin
import sys 
import os
import urllib

sys.path.insert(0, os.path.dirname(__file__))
import html
import html2text.html2text

class WgetMySitesCommand(sublime_plugin.WindowCommand):

    def run(self):
        settings = sublime.load_settings("SublimeWget.sublime-settings")
        self.sites = settings.get("sites",None)
        text_sites_for_selection = [site['name'] + ': ' + site['address'] for site in self.sites]
        self.window.show_quick_panel(text_sites_for_selection, self.run_wget_my_sites)
        

    def run_wget_my_sites(self,sites_index):
        if(sites_index != -1):
            wget_async(self, self.sites[sites_index]['name'],self.sites[sites_index]['address'])


class WgetInputCommand(sublime_plugin.WindowCommand):

    def run(self):
        self.window.show_input_panel("URL to retrieve", "", self.run_wget_input,None,None)

    def run_wget_input(self,the_input):
        wget_async(self,the_input,the_input)


def wget(self, window_name, the_url):
    if the_url.startswith('http://') or the_url.startswith('https://'):
        pass
    else:
        the_url = 'http://' + the_url

    page_html = urllib.request.urlopen(the_url).read().decode('utf-8')
    h = html2text.html2text.HTML2Text()
    page_md = h.handle(page_html)

    output_view = self.window.new_file();
    self.window.focus_view(output_view)
    output_view.run_command("append", {"characters": page_md})
    output_view.set_name('Wget: ' + window_name)
    output_view.set_read_only(True)
    output_view.set_scratch(True)

def wget_async(self, window_name, the_url):
    sublime.status_message('Retrieving page: ' + window_name + '...')
    sublime.set_timeout_async(lambda: wget(self,window_name,the_url),0)
