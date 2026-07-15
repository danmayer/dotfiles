;;; init.el --- minimal, portable Emacs config -*- lexical-binding: t; -*-

(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

;; Add package names here as they're actually wanted. Empty on purpose —
;; nothing here assumes a package beyond what Emacs ships with.
(setq package-selected-packages '())

(when package-selected-packages
  (unless package-archive-contents
    (package-refresh-contents))
  (dolist (pkg package-selected-packages)
    (unless (package-installed-p pkg)
      (package-install pkg))))

;; Sane, terminal-safe defaults
(setq inhibit-startup-screen t
      make-backup-files nil
      auto-save-default nil
      ring-bell-function 'ignore
      require-final-newline t)

(global-auto-revert-mode 1)
(column-number-mode 1)
(show-paren-mode 1)
(delete-selection-mode 1)

;; GUI-only settings: no-ops under `emacs -nw` (WSL, Codespaces)
(if (display-graphic-p)
    (progn
      (tool-bar-mode -1)
      (scroll-bar-mode -1)
      (set-face-attribute 'default nil :height 140))
  (menu-bar-mode -1))

;;; init.el ends here
