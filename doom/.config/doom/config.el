;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Prem Modha"
      user-mail-address "premmodhaofficial@gmail.com")

(setq doom-font (font-spec :family "Iosevka NF" :size 22 :weight 'regular :scalable 't)
     doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font Propo" :size 20))

;; (setq doom-theme 'doom-tokyo-night)
(use-package! spacemacs-theme
  :config
  (load-theme 'doom-feather-dark t))  ; Or 'spacemacs-light for the light variant

(setq display-line-numbers-type 'relative)

(setq org-directory "~/org/")
(setq org-agenda-files '("~/org/roam/"))
(setq org-roam-completion-everywhere t)

(setq org-roam-capture-templates
      '(("d" "default" plain
         "%?"
         :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
         :unnarrowed t)
        ("f" "fleating" plain
         (file "~/org/roam/templates/fleating.org")
         :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
         :unnarrowed t)
        ("t" "daily" plain
         (file "~/org/roam/templates/todo-daily.org")
         :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
         :unnarrowed t)
        )
      )

;; (print org-agenda-files)

;; If using Corfu
(after! corfu
  (setq corfu-auto t                 ; Enable auto completion
        corfu-auto-delay 0.0         ; No delay for completion
        corfu-auto-prefix 1))        ; Complete after 1 character

;; (setq +lookup-open-url-fn #'eww)
(setq! scroll-margin 30)
;; (setq! shell-file-name '/bin/zsh)

(set-frame-parameter nil 'alpha-background 60)
(add-to-list 'default-frame-alist '(alpha-background . 60))

(after! org
  (setq org-latex-compiler "xelatex"))  ;; Use XeLaTeX as default compiler

(use-package! obsidian
  :ensure t
  :demand t
  :config
  (obsidian-specify-path "~/Notes/second_brain/fleating_notes")
  (global-obsidian-mode t)
  :custom
  ;; This directory will be used for `obsidian-capture' if set.
  (obsidian-inbox-directory "Inbox")
  ;; Create missing files in inbox? - when clicking on a wiki link
  ;; t: in inbox, nil: next to the file with the link
  ;; default: t
  ;(obsidian-wiki-link-create-file-in-inbox nil)
  ;; The directory for daily notes (file name is YYYY-MM-DD.md)
  (obsidian-daily-notes-directory "Daily_Notes")
  ;; Directory of note templates, unset (nil) by default
  ;(obsidian-templates-directory "Templates")
  ;; Daily Note template name - requires a template directory. Default: Daily Note Template.md
  ;(obsidian-daily-note-template "Daily Note Template.md")
  :bind (:map obsidian-mode-map
  ;; Replace C-c C-o with Obsidian.el's implementation. It's ok to use another key binding.
  ("C-c C-o" . obsidian-follow-link-at-point)
  ;; Jump to backlinks
  ("C-c C-b" . obsidian-backlink-jump)
  ;; If you prefer you can use `obsidian-insert-link'
  ("C-c C-l" . obsidian-insert-wikilink)))
