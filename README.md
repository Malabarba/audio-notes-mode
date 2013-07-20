audio-notes-mode
================

Emacs mode to play audio notes synced from somewhere else.

![Screenshot 1](http://bruce-connor.github.io/control-pianobar/anm/screenshot-2013-07-16--095017.jpg)

Commentary:
===

`audio-notes-mode` is a way to manage small audio recordings that you
make in order to record thoughts.

After much struggle, I finally decided to stop trying to make speech
recognition work from my phone. Instead, I decided to just record
audio notes, and I wrote this package to automate the process of
playing them back at the computer.

I found this to be even faster, because I don't have to wait and see
if the speech recognition worked and I don't have to repeat the
message 1/3 of the time.

A tasker profile (which records and uploads these notes) is also
provided at the github page.

Workflow:
===

The idea is that you sync voice notes you record on your smartphone
into a directory on your PC. But you're free to use it in other ways.

When you activate this mode, it will play the first audio note in a
specific directory and wait for you to write it down. Once you're
finished, just call the next note with `anm/play-next` which is bound to `C-c C-j`. When you do
this, `audio-notes-mode` will *DELETE* the note which was already played
and start playing the next one. Once you've gone through all of them,
`audio-notes-mode` deactivates itself.

Instructions:
===

Configuration is simple. Require the package and define the following two variables:
    
    (require 'audio-notes-mode)
    (setq anm/notes-directory "~/Directory/where/your/notes/are/")
    (setq anm/goto-file "~/path/to/file.org") ;File in which you'll write your notes as they are played.

Then just choose how you want to activate it.

1) If you use `org-mobile-pull`, you can make `audio-notes-mode`
   activate whenever you call org-mobile-pull.

    (setq anm/hook-into-org-pull t)
    
2) The second options is to just bind `audio-notes-mode` to some key
   and call it when you want.

    (global-set-key [f8] 'audio-notes-mode)

If you installed manually, first require the feature with:
then use one of the methods above.

Customizations:
===

1) If you don't want notes to be deleted (maybe you want to back them up somewhere) you can edit the variable `anm/delete-command`. Just make sure this command does't leave them in the same folder, othervise ANM won't work.

2) You can have the current number of unread notes be displayed in the mode-line, just see the command `anm/display-on-modeline`.

License:
===

This file is NOT part of GNU Emacs.

This program is free softwareyou can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundationeither version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTYwithout even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.
