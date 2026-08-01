;;; velvet-mode.el --- Major mode for editing Ruby files -*- lexical-binding: t -*-

;; Copyright (C) 1994-2026 Free Software Foundation, Inc.

;; Authors: Petar Angelov
;; URL: https://www.emacswiki.org/cgi-bin/wiki/RubyMode
;; Created: Fri Feb  4 14:49:13 JST 1994
;; Keywords: languages velvet
;; Version: 1.2

;;; Commentary:

;; Provides font-locking, indentation support, and navigation for Velvet code.
;;
;; Still needs more docstrings; search below for TODO.

;;; Code:

(require 'generic-x)

(define-generic-mode
		'velvet-mode
	'("#")
	'("if" "else" "do" "end" "true" "false" "from" "to" "step" "while" "print" "puts")
	'(
		("+" "-" "*" "**" "/" "(" ")" "[" "]" "=" "==" "!=" "<" ">" "&&" "||" . 'font-lock-operator)
		("puts" "print" . 'font-lock-builtin)
		)
	'("\\.vv$") ;; files that autoload
	nil ;; other functions
	"A major mode for Velvet files"
	)

;;; Invoke velvet-mode when appropriate

;;;###autoload
(add-to-list 'auto-mode-alist
             (cons (concat "\\(?:\\.\\(?:"
                           "vv?\\|file"
                           "\\)\\'")
                   'velvet-mode))

;;;###autoload
(dolist (name (list "velvet" "vv"))
  (add-to-list 'interpreter-mode-alist (cons name 'velvet-mode)))

(provide 'velvet-mode)

;;; velvet-mode.el ends here
