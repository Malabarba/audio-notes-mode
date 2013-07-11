;;; audio-notes-mode.el --- Play audio notes synced from somewhere else.

;; Copyright (C) 2013 Artur Malabarba <bruce.connor.am@gmail.com>

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>
;; URL: http://github.com/Bruce-Connor/audio-notes-mode
;; Version: 0.1
;; Keywords: hypermedia convenience
;; ShortName: anm
;; Separator: /

;;; Commentary:
;;
;; `audio-notes-mode' is a way to managed small audio recordings that
;; you make in order to record thoughts.
;;
;; After much struggle, I finally decided to stop trying to make
;; speech recognition work from my phone. Instead, I decided to just
;; record audio notes, and I wrote this package to automate the
;; process of playing them back at the computer.
;;
;; I found this to be even faster, because I don't have to wait and
;; see if the speech recognition worked and I don't have to repeat the
;; message 1/3 of the time.
;;
;; A tasker profile (which records and uploads these notes) is also
;; provided at the github page.
;;
;; The idea is that you sync voice notes you record on your
;; smartphone into a directory on your PC. But you're free to use it
;; in other ways.
;;
;; When you activate this mode, it will play the first audio note in a
;; specific directory and wait for you to write it down. Once you're
;; finished, just call the next note with \\[anm/play-next]. When you
;; do this, `audio-notes-mode' will DELETE the note which was already
;; played and start playing the next one. Once you've gone through all
;; of them, `audio-notes-mode' deactivates itself.

;;; Instructions:
;;
;; INSTALLATION
;;
;; Configuration is simple. Require the package and define the following two variables:
;;           (require 'audio-notes-mode)
;;           (setq anm/notes-directory "~/Directory/where/your/notes/are/")
;;           (setq anm/goto-file "~/path/to/file.org") ;File in which you'll write your notes as they are played.
;;
;; Then just choose how you want to activate it.
;; 1) If you use `org-mobile-pull', you can do
;;       (setq anm/hook-into-org-pull t)
;;    and `audio-notes-mode' will activate whenever you call
;;    org-mobile-pull.
;;    
;; 2) The second options is to just bind `audio-notes-mode' to
;;    some key and call it when you want.
;;       (global-set-key [f8] 'audio-notes-mode)
;;
;; If you installed manually, first require the feature with:
;; then use one of the methods above.

;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 

;;; Change Log:
;; 0.1 - 20130710 - Created File.

;;; Code:


(defconst anm/version "0.1" "Version of the audio-notes-mode.el package.")

(defconst anm/version-int 1 "Version of the audio-notes-mode.el package, as an integer.")

(defun anm/bug-report ()
  "Opens github issues page in a web browser. Please send me any bugs you find, and please inclue your emacs and anm versions."
  (interactive)
  (browse-url "https://github.com/Bruce-Connor/audio-notes-mode/issues/new")
  (message "Your anm/version is: %s, and your emacs version is: %s.\nPlease include this in your report!"
           anm/version emacs-version))

(defun anm/customize ()
  "Open the customization menu in the `audio-notes-mode' group."
  (interactive)
  (customize-group 'audio-notes-mode t))


(defcustom anm/display-greeting t
  "Whether we explain the keybindings upon starting the mode."
  :type 'boolean
  :group 'audio-notes-mode
  :package-version '(audio-notes-mode . "0.1"))

(defcustom anm/notes-directory (concat
                                (if (boundp 'org-directory)
                                    org-directory
                                  "~/Dropbox/") "Mobile/")
  "Directory where recorded notes are stored."
  :type 'string
  :group 'audio-notes-mode)

(defcustom anm/goto-file nil
  "File to visit when `audio-notes-mode' is entered. This should be your TODO-list file.

If nil, nothing will be visited.
If a string, it is the path to the file which will be visited
when you activate `audio-notes-mode'."
  :type '(choice string nil)
  :group 'audio-notes-mode)

(defcustom anm/file-regexp "^[^\\.].*\.\\(mp[34]\\|wav\\)$"
     "Regexp which filenames must match to be managed by OAN.

Default is to play only mp4, mp3 and wav, and to exclude hidden files."
     :type 'regexp
     :group 'audio-notes-mode)

(defcustom anm/lighter (if (char-displayable-p ?▶) " ▶" " anm")
  "Ligher for the mode-line."
  :type 'string
  :group 'audio-notes-mode
  :package-version '(audio-notes-mode . "0.1"))

(defcustom anm/hook-into-org-pull nil
  "If this is non-nil, `audio-notes-mode' will be called every time (after) you do an org-pull."
  :type 'boolean
  :group 'audio-notes-mode
  :package-version '(audio-notes-mode . "0.1"))

(defcustom anm/after-play-hook '()
  "Hooks run every time a note is played (immediately after playing it)."
  :type 'hook
  :group 'audio-notes-mode
  :package-version '(audio-notes-mode . "0.1"))

(defcustom anm/before-play-hook '()
  "Hooks run every time a note is played (immediately before playing it)."
  :type 'hook
  :group 'audio-notes-mode
  :package-version '(audio-notes-mode . "0.1"))

(defcustom anm/process-buffer-name "*Audio notes player*"
  "Name of the process buffer."
  :type 'string
  :group 'audio-notes-mode
  :package-version '(audio-notes-mode . "0.1"))

(defcustom anm/player (if (fboundp 'play-sound-internal) 'internal "mplayer")
  "Which player to use for the audio files.
If it's the symbol 'internal (default), uses emacs internal player.
If it's a string, uses that executable on the filesystem."
  :type '(choice (const :tag "Emacs internal player" t)
                 (string :tag "Executable name"))
  :group 'audio-notes-mode
  :package-version '(audio-notes-mode . "0.1"))

(defcustom anm/player-args '(file)
  "Extra arguments to be passed to the audio player in `anm/player'. Filename is added AFTER all of these."
  :type '(repeat (choice (const :tag "File name" 'file)
                         (string :tag "Extra arguments")))
  :group 'audio-notes-mode
  :package-version '(audio-notes-mode . "0.1"))

(defvar anm/dired-buffer     nil "The buffer displaying the notes.")
(defvar anm/goto-file-buffer nil "The buffer the user asked to open.")
(defvar anm/process-buffer   nil "Process buffer.")
(defvar anm/current          nil "Currently played file.")
(defvar anm/did-visit        nil "Did we visit a file and mess up the configuration.")
(defvar anm/found-files      nil "")

(defconst anm/greeting
  "You're in `audio-notes-mode'. This mode will deactivate after you go through your notes, to quit manually use \\[audio-notes-mode].
\\[anm/play-next]: DELETES this audio note and moves to the next one.
\\[anm/play-current]: Replays this audio note.
To disable this message, edit `anm/display-greeting'."
  "Greeting message when entering mode.")

;;;###autoload
(defadvice org-mobile-pull (after anm/after-org-mobile-pull-advice activate)
  "Check for audio notes after every org-pull."
  (when anm/hook-into-org-pull (audio-notes-mode 1)))

(defun anm/play-next ()
  "Play next audio note. If no more notes, exit `audio-notes-mode'."
  (interactive)
  ;; Delete previously played note
  (if (file-readable-p anm/current)
      (if (file-writable-p anm/current)
          (progn (delete-file anm/current t)
                 (setq anm/current nil))
        (audio-notes-mode -1)
        (error "File %s can't be deleted.\nCheck file permissions and fix this.\n(Exiting)" anm/current))
    (warn "File %s not found for deletion." anm/current))
  ;; Play the next one. If there isn't one, just exit play-notes-mode.
  (anm/play-current))

(defun anm/play-current ()
  "Play current audio note."
  (interactive)
  (let* ((files (anm/list-files))
         (file (or anm/current (car files)))
         (sn (if file (file-name-nondirectory file) "")))
    (if file
        (progn
          (if anm/current
              (message "Replaying %s" sn)
            (setq anm/current file)
            (message "%s notes left. Playing %s" (length files) sn))
          (with-current-buffer anm/dired-buffer
            (goto-char (point-min))
            (search-forward sn)
            (revert-buffer))
          (run-hooks anm/before-play-hook)
          (anm/play-file file)
          (run-hooks anm/after-play-hook))
      (message "No more notes. Exiting `audio-notes-mode'.")
      (audio-notes-mode -1))))

(defun anm/play-file (file)
  "Play sound file."
  (unless (file-readable-p file) (error "FILE isn't a file."))
  (unless anm/player (error "`anm/player' can't be nil."))
  (if (eq anm/player 'internal) 
      (play-sound-file (expand-file-name file))
    (setq anm/process (eval (concatenate 'list '(start-process "anm/player" anm/process-buffer anm/player)
                                         (map 'list 'eval anm/player-args))))))

(defun anm/list-files ()
  "List all non-hidden files in `anm/notes-directory'."
  (directory-files anm/notes-directory t anm/file-regexp))

;;;###autoload
(define-minor-mode audio-notes-mode
  "`audio-notes-mode' is a way to manage small audio recordings that you make in order to record thoughts.

When you activate it, it will play the first audio note in a
specific directory and wait for you to write it down. Once you're
finished, just call the next note with C-c C-j.
When you do this, `audio-notes-mode' will DELETE the note which
was already played and start playing the next one. Once you've
gone through all of them, `audio-notes-mode' deactivates itself."
  nil anm/lighter
  '(("\n" . anm/play-next)
    ("" . anm/play-current)
    ("" . audio-notes-mode))
  :global t
  :group 'audio-notes-mode
  (if audio-notes-mode
      ;; ON
      (if anm/player
          (let ((file (car (anm/list-files))))
            (if (not file)
                (audio-notes-mode -1)
              (setq anm/found-files t)
              (when anm/display-greeting (message (substitute-command-keys anm/greeting)))
              (window-configuration-to-register :anm/before-anm-configuration)
              (delete-other-windows)
              (when anm/goto-file
                (setq anm/did-visit t)
                (setq anm/goto-file-buffer (find-file anm/goto-file)))
              (let ((focusWin (selected-window))
                    diredSize)
                ;; Created dired window
                (select-window (split-window-right))
                (setq anm/dired-buffer (find-file anm/notes-directory))
                (revert-buffer)
                (goto-char (point-min))
                (search-forward (file-name-nondirectory file))
                ;; Create process window
                (when (stringp anm/player)
                  (setq diredSize (line-number-at-pos (point-max)))
                  (select-window (split-window-below (1- diredSize)))
                  (setq anm/process-buffer
                        (switch-to-buffer
                         (generate-new-buffer anm/process-buffer-name))))
                ;; Back to writing window
                (select-window focusWin))
              (anm/play-current)))
        ;; If anm/player was nil
        (audio-notes-mode -1)
        (error "`anm/player' can't be nil."))
    ;; OFF
    (setq anm/current nil)
    (when (buffer-live-p anm/process-buffer)
      (kill-buffer anm/process-buffer))
    (if (not anm/found-files)
        (message "[OAN]:No audio notes found in \"%s\"." anm/notes-directory)
      (setq anm/found-files nil)
      (jump-to-register :anm/before-anm-configuration)
      (when anm/did-visit
        (setq anm/did-visit nil)
        (bury-buffer anm/goto-file-buffer))
      (when (get-buffer-window anm/dired-buffer)
        (condition-case nil        ;Don't bug me if it's the only window
            (delete-window (get-buffer-window anm/dired-buffer))
          (error nil)))
      (bury-buffer anm/dired-buffer))))

(provide 'audio-notes-mode)
;;; audio-notes-mode.el ends here.
