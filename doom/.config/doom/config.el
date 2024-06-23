;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Prem Modha"
      user-mail-address "premmodhaofficial@gmail.com")

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 25 :weight 'regular :scalable 't)
     doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font Propo" :size 20))

(setq doom-theme 'doom-tokyo-night)

(setq display-line-numbers-type 'relative)

(setq org-directory "~/org/")

(setq +lookup-open-url-fn #'eww)
(setq! scroll-margin 30)
;; (setq! shell-file-name '/bin/zsh)

(set-frame-parameter nil 'alpha-background 75)
(add-to-list 'default-frame-alist '(alpha-background . 90))
