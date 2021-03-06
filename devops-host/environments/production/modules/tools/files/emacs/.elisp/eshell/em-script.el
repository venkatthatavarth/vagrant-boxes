;;; em-script --- Eshell script files

;; Copyright (C) 1999, 2000 Free Software Foundation

;; Author: John Wiegley <johnw@gnu.org>

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

(provide 'em-script)

(eval-when-compile (require 'esh-maint))

(defgroup eshell-script nil
  "This module allows for the execution of files containing Eshell
commands, as a script file."
  :tag "Running script files."
  :group 'eshell-module)

;;; Commentary:

;;; User Variables:

(defcustom eshell-script-load-hook '(eshell-script-initialize)
  "*A list of functions to call when loading `eshell-script'."
  :type 'hook
  :group 'eshell-script)

(defcustom eshell-login-script (concat eshell-directory-name "login")
  "*If non-nil, a file to invoke when starting up Eshell interactively.
This file should be a file containing Eshell commands, where comment
lines begin with '#'."
  :type 'file
  :group 'eshell-script)

(defcustom eshell-rc-script (concat eshell-directory-name "profile")
  "*If non-nil, a file to invoke whenever Eshell is started.
This includes when running `eshell-command'."
  :type 'file
  :group 'eshell-script)

;;; Functions:

(defun eshell-script-initialize ()
  "Initialize the script parsing code."
  (make-local-variable 'eshell-interpreter-alist)
  (setq eshell-interpreter-alist
	(cons '((lambda (file)
		  (string= (file-name-nondirectory file)
			   "eshell")) . eshell/source)
	      eshell-interpreter-alist))
  (make-local-variable 'eshell-complex-commands)
  (setq eshell-complex-commands
	(append '("source" ".") eshell-complex-commands))
  ;; these two variables are changed through usage, but we don't want
  ;; to ruin it for other modules
  (let (eshell-inside-quote-regexp
	eshell-outside-quote-regexp)
    (and (not eshell-non-interactive-p)
	 eshell-login-script
	 (file-readable-p eshell-login-script)
	 (eshell-do-eval
	  (list 'eshell-commands
		(catch 'eshell-replace-command
		  (eshell-source-file eshell-login-script))) t))
    (and eshell-rc-script
	 (file-readable-p eshell-rc-script)
	 (eshell-do-eval
	  (list 'eshell-commands
		(catch 'eshell-replace-command
		  (eshell-source-file eshell-rc-script))) t))))

(defun eshell-source-file (file &optional args subcommand-p)
  "Execute a series of Eshell commands in FILE, passing ARGS.
Comments begin with '#'."
  (interactive "f")
  (let ((orig (point))
	(here (point-max))
	(inhibit-point-motion-hooks t)
	after-change-functions)
    (goto-char (point-max))
    (insert-file-contents file)
    (goto-char (point-max))
    (throw 'eshell-replace-command
	   (prog1
	       (list 'let
		     (list (list 'eshell-command-name (list 'quote file))
			   (list 'eshell-command-arguments
				 (list 'quote args)))
		     (let ((cmd (eshell-parse-command (cons here (point)))))
		       (if subcommand-p
			   (setq cmd (list 'eshell-as-subcommand cmd)))
		       cmd))
	     (delete-region here (point))
	     (goto-char orig)))))

(defun eshell/source (&rest args)
  "Source a file in a subshell environment."
  (eshell-eval-using-options
   "source" args
   '((?h "help" nil nil "show this usage screen")
     :show-usage
     :usage "FILE [ARGS]
Invoke the Eshell commands in FILE in a subshell, binding ARGS to $1,
$2, etc.")
   (eshell-source-file (car args) (cdr args) t)))

(put 'eshell/source 'eshell-no-numeric-conversions t)

(defun eshell/. (&rest args)
  "Source a file in the current environment."
  (eshell-eval-using-options
   "." args
   '((?h "help" nil nil "show this usage screen")
     :show-usage
     :usage "FILE [ARGS]
Invoke the Eshell commands in FILE within the current shell
environment, binding ARGS to $1, $2, etc.")
   (eshell-source-file (car args) (cdr args))))

(put 'eshell/. 'eshell-no-numeric-conversions t)

;;; Code:

;;; em-script.el ends here
