;;; init.el --- Chunyang Xu's Emacs Configuration  -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2017  Chunyang Xu

;; Author: Chunyang Xu <mail@xuchunyang.me>
;; URL: https://github.com/xuchunyang/emacs.d

;;; Code:


;;; Debug init file

(defun chunyang-quit-init-el ()
  "Call it from init file to quit loading immediately."
  (when load-in-progress
    (with-current-buffer " *load*"
      (message "%s:%s:%s"
               load-file-name
               (line-number-at-pos)
               (buffer-substring-no-properties
                (line-beginning-position)
                (line-end-position)))
      (goto-char (point-max)))))


;;; Start up

(require 'package)

(setq package-archives
      '(("gnu"    . "http://elpa.emacs-china.org/gnu/")
        ("org"    . "http://elpa.emacs-china.org/org/")
        ("melpa"  . "http://elpa.emacs-china.org/melpa/")
        ("user42" . "http://elpa.emacs-china.org/user42/")))

;; Don't share the same elpa accross different versions of Emacs
(setq package-user-dir
      (locate-user-emacs-file (concat "elpa-" emacs-version)))

(package-initialize)

(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error :no-message)

;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; use-package.el is no longer needed at runtime
(eval-when-compile
  (require 'use-package)

  ;; Add new keyword
  ;; <https://github.com/jwiegley/use-package#extending-use-package-with-new-or-modified-keywords>
  (add-to-list 'use-package-keywords :homepage t)
  (defun use-package-normalize/:homepage (&rest _))
  (defun use-package-handler/:homepage (&rest _))
  (add-to-list 'use-package-keywords :tips t)
  (defun use-package-normalize/:tips (&rest _))
  (defun use-package-handler/:tips (&rest _))
  (add-to-list 'use-package-keywords :summary t)
  (defun use-package-normalize/:summary (&rest _))
  (defun use-package-handler/:summary (&rest _)))

(require 'diminish)                ;; if you use :diminish
(require 'bind-key)                ;; if you use any :bind variant

;; My private packages
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))


;;; Emacs Compatibility

(use-package chunyang-emacs-compatibility)


;;; Require helper libraries

;; Make sure `seq.el' is installed for Emacs 24
(use-package seq
  :ensure t
  :defer t)

(use-package dash
  :ensure t
  :defer t
  :config (dash-enable-font-lock))


;;; Initialization

;; Disable the site default settings. See (info "(emacs) Init File")
(setq inhibit-default-init t)

;; Don't show "For information about GNU Emacs and the GNU system, type C-h
;; C-a." after startup
(setq inhibit-startup-echo-area-message "xcy")

(setq initial-major-mode 'fundamental-mode)

;; Load personal information
;; (load "~/.private.el" :no-error)

;; Make ~/.emacs.d clean
(use-package no-littering
  :ensure t)


;;; macOS

(defconst *is-mac* (eq system-type 'darwin))

(use-package ns-win
  :if *is-mac*
  :no-require t
  :defer t
  :init
  (setq mac-command-modifier 'meta
        mac-option-modifier 'control))

(use-package exec-path-from-shell
  :if (eq window-system 'ns)       ; Only for the official Cocoa Emacs
  :ensure t
  :defer t
  :init
  (let ((path (eval-when-compile
                (require 'exec-path-from-shell)
                (exec-path-from-shell-getenv "PATH"))))
    (setenv "PATH" path)
    (setq exec-path (append (parse-colon-path path) (list exec-directory)))))

(use-package chunyang-mac
  :if *is-mac*
  :commands (chunyang-mac-Terminal-send-region
             chunyang-mac-Terminal-cd
             chunyang-mac-Finder-reveal))

;; XXX WIP MacPorts interface (manage ports, discover ports etc)
(use-package macports
  :if *is-mac*
  :commands (macports-list-port
             macports-info-port))


;;; GNU/Linux

(defconst *is-gnu-linux* (eq system-type 'gnu/linux))

(use-package chunyang-linux
  :if *is-gnu-linux*
  :commands chunyang-linux-gnome-terminal-cd
  :bind (("<S-insert>" . insert-x11-primary-selection)))

(use-package grab-x-link
  :if *is-gnu-linux*
  :no-require t               ; Silence byte-compile warnning on macOS
  :commands grab-x-link
  :load-path "/home/xcy/src/grab-x-link")


;;; User Interface

;; It's possible that Emacs is not built with Tool Bar and Scroll Bar
;; support, so we need to test firstly
(and (bound-and-true-p tool-bar-mode)
     (tool-bar-mode -1))
(and (bound-and-true-p scroll-bar-mode)
     (scroll-bar-mode -1))

(defconst *is-windows* (eq system-type 'windows-nt))

;; Disable `menu-bar-mode' except macOS & Windows
(unless (or *is-mac*
            ;; I don't familiar with Windows, thus that menu bar helps
            *is-windows*)
  (menu-bar-mode -1))

;; Type M-x `about-emacs' to see it
(setq inhibit-startup-screen t)

;; Don't ring the bell (usually when Quit with C-g and undefined key
;; binding)
(setq ring-bell-function #'ignore)


;;; Yes Or No (not safe)

(fset 'yes-or-no-p #'y-or-n-p)


;;; Font
(cl-case window-system
  ;; 'mac -> EmacsMac.app Carbon
  ;; 'ns  -> Emacs.app Cocoa
  ((mac ns)
   ;; 等宽: Source Code Pro 13 + STkaiti 16
   (setq face-font-rescale-alist `(("STkaiti" . ,(/ 16.0 13))))

   (set-face-attribute 'default nil :font "Source Code Pro-13")

   (set-fontset-font t 'han      (font-spec :family "STkaiti"))
   (set-fontset-font t 'cjk-misc (font-spec :family "STkaiti"))

   ;; 测试
   "
| 软件      |  版本 | 发布日期     |
|-----------+-------+--------------|
| GNU Emacs |  25.1 | 2016 年 9 月 |
| Org       | 9.9.5 | 2017 年 2 月 |
"
   ;; 问题：不等高 Height
   )
  ('w32
   (set-face-attribute 'default nil :font "Source Code Pro-10"))
  ('x (dolist (charset '(kana han symbol cjk-misc bopomofo))
        (set-fontset-font (frame-parameter nil 'font)
                          charset
                          (font-spec :family "Noto Sans Mono CJK SC" :size 14)))))


;; Theme

;; I change theme periodically so I don't want hard-code it here,
;; instead, I use the Custom via 'M-x customize-themes'.

(use-package spacemacs-theme
  :ensure t
  :no-require t                      ; Silence byte-compiling warnings
  :defer t
  :init (setq spacemacs-theme-comment-bg nil
              spacemacs-theme-org-height nil))

(use-package tomorrow-theme
  :ensure color-theme-sanityinc-tomorrow
  :no-require t
  :defer t)

;; Mode line
(setq-default mode-line-format
              '("%e" mode-line-front-space
                ;; Standard info about the current buffer
                mode-line-mule-info
                mode-line-client
                mode-line-modified
                mode-line-remote
                mode-line-frame-identification
                mode-line-buffer-identification "    " mode-line-position
                ;; For debug some elisp program
                ;; (:eval (format "%-5d" (point)))
                (projectile-mode projectile-mode-line)
                (vc-mode (:propertize (:eval vc-mode) face italic))
                (helm-alive-p
                 (:eval (when (eq (current-buffer) helm-current-buffer)
                          (propertize " Helm-current " 'face 'bold))))
                ;; Other modes
                " " mode-line-modes mode-line-misc-info mode-line-end-spaces))

(column-number-mode)
(size-indication-mode)

(setq echo-keystrokes 0.6)              ; 默认 1 秒，更快地显示未完成地按键

(use-package time
  :defer t
  :config
  ;; M-x display-time-world
  (add-to-list 'display-time-world-list '("Asia/Shanghai" "上海")))


;; Prefer the old fashion (< Emacs 25) `quote' in *Help* & *Messages*
;; WARNNING: This is not a user option
;; (setq text-quoting-style 'grave)

;;; Emacs session persistence
(use-package desktop                    ; frame/window/buffer and global vars
  :disabled t
  :if (display-graphic-p)
  :init
  (setq desktop-load-locked-desktop nil)
  (desktop-save-mode)
  :config
  (setq desktop-restore-frames nil)
  ;; Save the content of *scratch* across sessions
  (add-to-list 'desktop-globals-to-save 'initial-scratch-message)
  (add-hook 'kill-emacs-hook
            (lambda ()
              (when (get-buffer "*scratch*")
                (with-current-buffer "*scratch*"
                  (widen)
                  ;; FIXME: Emacs deals with `initial-scratch-message' with
                  ;; `substitute-command-keys', which does a lot unwanted
                  ;; conversions.
                  (setq initial-scratch-message
                        (buffer-string)))))))

;; Maximize Emacs frame on start-up
;; (add-to-list 'default-frame-alist '(fullscreen . maximized))

(use-package savehist         ; Minibuffer history
  :disabled t                 ; Disable for now to reduce startup time
  :config
  (savehist-mode)
  (setq history-length 1000
        history-delete-duplicates t
        savehist-additional-variables
        '(extended-command-history
          ;; Record recent directories. To use, type
          ;; C-u C-x C-f (helm-find-files)
          helm-ff-history)))

(use-package recentf                    ; Recent files
  :init
  (setq recentf-max-saved-items 512
        recentf-exclude (list "/\\.git/.*\\'"      ; Git contents
                              "/\\.emacs\\.d/elpa" ; ELPA
                              "/etc/.*\\'" ; Package configuration
                              "/var/.*\\'" ; Package data
                              ".*\\.gz\\'"
                              "TAGS"
                              ".*-autoloads\\.el\\'"))
  ;; FIXME:
  ;; Not sure why use-package gives a warnning about this on only
  ;; Emacs 26.0.50. It is OK since helm will enable it automatically.
  ;; :config (recentf-mode)
  :defer t)

(use-package recentb
  :disabled t                    ; Disable for now to reduce init time
  :config (recentb-mode))

(use-package bookmark
  :defer t
  :config
  ;; Save immediately when make or delete a bookmark
  (setq bookmark-save-flag 1))

(use-package saveplace                  ; Save point position in files
  :init (add-hook 'after-init-hook #'save-place-mode))


;;; Minibuffer

;; Give useful pormpt during M-! (`shell-command') etc
(use-package prompt-watcher
  :config (prompt-watcher-mode))

;; NOTE Try this for a while. Disable if not like
(use-package minibuf-eldef ; Only show defaults in prompts when applicable
  :init
  ;; Must be set before minibuf-eldef is loaded
  (setq minibuffer-eldef-shorten-default t)
  :config
  (minibuffer-electric-default-mode))

;; Inspired by isearch's C-w `isearch-yank-word-or-char'.
(defun chunyang-minibuffer-yank-word ()
  "Yank word at point in the buffer when entering minibuffer into minibuffer."
  (interactive)
  (require 'subr-x)
  (with-selected-window (minibuffer-selected-window)
    (when-let ((word (current-word)))
      (with-selected-window (active-minibuffer-window)
        (insert word)))))

(define-key minibuffer-local-map "\C-w" #'chunyang-minibuffer-yank-word)

(use-package chunyang-helm)


;;; Buffers, Windows and Frames

(use-package uniquify            ; Make buffer names unique (turn on by default)
  :defer t
  :config (setq uniquify-buffer-name-style 'forward))

(use-package autorevert                 ; Auto-revert buffers of changed files
  :diminish auto-revert-mode
  :init (global-auto-revert-mode))

(use-package chunyang-simple
  :bind (("C-x 3" . chunyang-split-window-right)
         ("C-x 2" . chunyang-split-window-below)
         ("C-h t" . chunyang-switch-scratch)
         :map lisp-interaction-mode-map
         ("C-c C-l" . scratch-clear))
  :commands (chunyang-window-click-swap
             chunyang-abbreviate-file-name-at-point
             chunyang-expand-file-name-at-point
             chunyang-show-number-as-char))

(use-package chunyang-misc
  :commands chunyang-open-another-emacs)

(use-package chunyang-buffers    ; Personal buffer tools
  :config (add-hook 'kill-buffer-query-functions
                    #'lunaryorn-do-not-kill-important-buffers))

(bind-key "O"     #'delete-other-windows special-mode-map)
(bind-key "Q"     #'kill-this-buffer     special-mode-map)
(bind-key "C-x k" #'kill-this-buffer)
(bind-key "C-x K" #'kill-buffer)

(use-package ibuffer
  :defer t
  :config
  ;; Since I used to M-o
  (unbind-key "M-o" ibuffer-mode-map))

(use-package ace-window
  :ensure t
  :defer t
  :preface
  (defun chunyang-ace-window (arg)
    "A modified version of `ace-window'.
When number of window <= 3, invoke `other-window', otherwise `ace-window'.
One C-u, swap window, two C-u, `chunyang-window-click-swap'."
    (interactive "p")
    (cl-case arg
      (0
       (setq aw-ignore-on
             (not aw-ignore-on))
       (ace-select-window))
      (4 (ace-swap-window))
      (16 (call-interactively #'chunyang-window-click-swap))
      (t (if (<= (length (window-list)) 3)
             (other-window 1)
           (ace-select-window)))))
  :bind ("M-o" . chunyang-ace-window)
  :config
  (setq aw-ignore-current t)
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package winner
  :disabled t
  :bind (("M-N" . winner-redo)
         ("M-P" . winner-undo))
  :config (winner-mode))

(use-package eyebrowse
  :disabled t
  :ensure t
  :config (eyebrowse-mode))

(use-package shackle
  :ensure t
  :disabled t
  :init (shackle-mode)
  :config (setq shackle-rules '(("\\‘\\*helm.*?\\*\\'" :regexp t :align t :ratio 0.4))))

;; Frames
(setq frame-resize-pixelwise t          ; Resize by pixels
      frame-title-format
      '(:eval (if (buffer-file-name)
                  (abbreviate-file-name (buffer-file-name)) "%b")))

(use-package frame
  :preface
  (defun chunyang-toggle-frame-transparency ()
    (interactive)
    (if (equal (frame-parameter nil 'alpha) 85)
        (set-frame-parameter nil 'alpha 100)
      (set-frame-parameter nil 'alpha 85)))
  (defun chunyang-frame-left-half ()
    (interactive)
    (set-frame-width (selected-frame) (/ 177 2))
    (set-frame-position (selected-frame) 0 23))
  (defun chunyang-frame-right-half ()
    (interactive)
    (set-frame-width (selected-frame) (/ 177 2))
    (set-frame-position (selected-frame) 720 23))
  (defun chunyang-frame-center ()
    (interactive)
    (let ((frame (selected-frame)))
      (set-frame-width frame 93)
      (set-frame-height frame 36)
      (set-frame-position frame 337 104)))
  :bind (("C-c t F" . toggle-frame-fullscreen)
         ("C-c t m" . toggle-frame-maximized)
         ("C-c w f" . toggle-frame-maximized)
         ("C-c w l" . chunyang-frame-left-half)
         ("C-c w r" . chunyang-frame-right-half)
         ("C-c w c" . chunyang-frame-center))
  :config
  ;; (add-to-list 'initial-frame-alist '(maximized . fullscreen))
  (unbind-key "C-x C-z"))


;;; File handle
;; Keep backup and auto save files out of the way
;; NOTE: Commenting this out because `no-littering.el' is doing this for me
;; (setq backup-directory-alist `((".*" . ,(locate-user-emacs-file ".backup")))
;;       auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

(defconst *is-mac-port* (boundp 'mac-carbon-version-string)
  "Is running the Emacs Mac Port?
See URL `https://bitbucket.org/mituharu/emacs-mac'.")

;; For Cocoa Emacs.app, trashing just means move file to
;; ~/.local/share/Trash/, which is not very useful, so don't enable
;; this feature in such case.
(unless (and *is-mac* (not *is-mac-port*))
  ;; Delete files to trash
  (setq delete-by-moving-to-trash t))

;; Exit Emacs without confirm kill processes (Emacs-26.1)
(setq confirm-kill-processes nil)

(use-package files
  :bind (("C-c f u" . revert-buffer)
         ("C-c f n" . normal-mode))
  :preface
  (defun chunyang-add-file-local-variable-post (&rest _r)
    "Ask to save and revert the buffer."
    (when (y-or-n-p "Save and revert this file?")
      (save-buffer)
      (revert-buffer nil :no-confirm)))
  (advice-add 'add-file-local-variable :after #'chunyang-add-file-local-variable-post)
  (advice-add 'add-file-local-variable-prop-line :after #'chunyang-add-file-local-variable-post))

;; TODO Try this first, if useless, remove.
(defun chunyang-help ()
  "My *personal* little helper."
  (interactive)
  (if (eq major-mode 'dired-mode)
      (let* ((commands
              '(dired-hide-details-mode
                dired-omit-mode
                wdired-change-to-wdired-mode))
             (tips
              (mapconcat
               (lambda (cmd)
                 (format "%-30s    %s"
                         cmd (mapconcat
                              'key-description
                              ;; Ignore menu bar
                              (cl-remove-if
                               (lambda (key)
                                 (eq (elt key 0) 'menu-bar))
                               (where-is-internal cmd))
                              ", ")))
               commands "\n")))
        (message "%s" tips))
    (user-error "Unsupported context")))

(bind-key "C-h p" #'chunyang-help) ; The default binding of 'C-h p' is `finder-by-keyword'

;; Dired Tips:
;;
;; - 'C-u s' to edit ls switch
;; - 'C-x C-q' (`dired-toggle-read-only') or
;;   `wdired-change-to-wdired-mode' to edit dired buffer

(use-package dired                      ; Directory Editor
  :defer t
  :preface
  (defun chunyang-dired-view-file-other-window ()
    (interactive)
    (cl-letf (((symbol-function 'view-file) #'view-file-other-window))
      (dired-view-file)))
  :config
  (bind-key "V" #'chunyang-dired-view-file-other-window dired-mode-map)

  ;; It's better to use ls(1) from GNU Coreutils since it supports
  ;; --dired, thus Dired doesn't have to search filename. See
  ;; `insert-directory-program'.

  (setq dired-listing-switches "-Alh")

  ;; `dired-listing-switches' can't contain whitespace before
  ;; the commit c71b718be86bdda7b51c8ea0da30aa896a7833fe
  ;;
  ;; (when (version<= "26.0.50.2" emacs-version)
  ;;   (setq dired-listing-switches
  ;;         (combine-and-quote-strings '("-Alh" "--time-style=+%_m月 %d %H:%M"))))
  ;;
  ;; FIXME
  ;; 1. 这回导致 Tramp 的 Dired 不能正常工作
  ;; 2. Mode line 有点问题

  ;; Use directory from other dired window as target directory while
  ;; copying and renaming.
  (setq dired-dwim-target t)

  (when *is-mac*
    (defun chunyang-dired-reveal-file-in-Finder ()
      (interactive)
      (let ((file (dired-get-file-for-visit)))
        (chunyang-mac-Finder-reveal file)))

    (defun chunyang-dired-quick-look-file ()
      (interactive)
      (let ((file (dired-get-file-for-visit)))
        (shell-command (format "qlmanage -p '%s' &> /dev/null" file))))

    ;; It is very cool but can't compare with Finder, anyway,
    ;; qlmanage(1) is just for debugging.
    ;; (bind-key "SPC" #'chunyang-dired-quick-look-file dired-mode-map)
    ))

;; (info "(dired-x) Features")
(use-package dired-x
  ;; Note that dired-x also sets the following binding when it gets
  ;; loaded by default.
  :bind (("C-x C-j"   . dired-jump)
         ("C-x 4 C-j" . dired-jump-other-window))
  :config

  ;; On macOS, use open(1) as guess shell command for some files
  (when *is-mac*
    (setq dired-guess-shell-alist-user
          (list
           (list (rx (and "."
                          (or
                           ;; Videos
                           "mp4" "avi" "mkv" "rmvb"
                           ;; Torrent
                           "torrent"
                           ;; PDF
                           "pdf"
                           ;; Image
                           "gif" "png" "jpg" "jpeg")
                          string-end)) "open")))))

(use-package async
  :ensure t
  :defer t
  :init (eval-after-load 'dired '(dired-async-mode)))

(use-package direx                      ; Alternative to Dired
  :ensure t
  :defer t)

(use-package launch                     ; Open files in external programs
  :disabled t
  :ensure t
  :defer t)


;;; Basic Editing

;; Disable tabs, but given them proper width
(setq-default indent-tabs-mode nil
              tab-width 8)

;; Indicate empty lines at the end of a buffer in the fringe, but require a
;; final new line
(setq indicate-empty-lines t
      require-final-newline t)

(setq kill-ring-max 200                 ; More killed items
      ;; Save the contents of the clipboard to kill ring before killing
      save-interprogram-paste-before-kill t)

(use-package electric                   ; Electric code layout
  :init (electric-layout-mode))

;; TODO: 支持中文标点（引号等。为什么中文括号默认就支持？）
;; TODO: 如何删除 pair （paredit 这样的工具有很好的支持，但是非 lisp 环境下怎么办？）
;; TODO: 如何直接改变 pair (cycle-quotes)
(use-package elec-pair                  ; Electric pairs
  :init (electric-pair-mode))

;; I have used 'M-l' to run `helm-mini' for a long time
(define-key global-map "\M-L" #'downcase-dwim)

;; Configure a reasonable fill column, indicate it in the buffer and
;; enable automatic filling
;; (setq-default fill-column 80)
;;
;; or change it interactively via C-x f (`set-fill-column')

;; I prefer indent long-line code myself
;; (setq comment-auto-fill-only-comments t)

;; (add-hook 'text-mode-hook #'auto-fill-mode)
;; (add-hook 'prog-mode-hook #'auto-fill-mode)

;; (diminish 'auto-fill-function)          ; Not `auto-fill-mode' as usual

;; To change `fill-prefix' interactively, type C-x . (`set-fill-prefix')

;; (global-visual-line-mode)

(use-package visual-line-mode
  :defer t
  :no-require t
  :init
  ;; NOTE: `visual-line-mode' 或者说 `word-wrap' 不能处理中文
  ;; https://emacs-china.org/t/topic/2616
  ;;
  ;; 但是没了 `word-wrap'，也就没太多理由再用 `visual-line-mode'（？）
  ;; 因为 Emacs 默认本来就开启了 Line Wrap
  ;;
  ;; (defun chunyang-disable-word-wrap ()
  ;;   (setq word-wrap nil))
  ;; (add-hook 'visual-line-mode-hook #'chunyang-disable-word-wrap)

  ;; (define-minor-mode chinese-visual-line-mode
  ;;   "Like Visual Line mode excepting turning off `word-wrap'."
  ;;   :lighter ""
  ;;   (if chinese-visual-line-mode
  ;;       (progn (visual-line-mode)
  ;;              (setq word-wrap nil))
  ;;     (visual-line-mode -1)))
  )

(use-package visual-fill-column         ; `fill-column' for `visual-line-mode'
  :disabled t
  ;; TODO: use-package: 自定义关键词
  ;; :description "定制 Emacs 自带 visual-line-mode 的宽度"
  ;; :url "foobar"
  :ensure t
  :defer t
  :init
  (setq visual-fill-column-width fill-column)
  ;; (setq visual-fill-column-fringes-outside-margins nil)
  (add-hook 'visual-line-mode-hook
            (defun visual-fill-column-toggle ()
              (visual-fill-column-mode (or visual-line-mode -1)))))

;; NOTE: `visual-line-mode' 似乎假定了字与字之间使用空格隔开的！？所以处理中文应该有问题吧！
;;       好像有没问题！我不是 100% 确定到底有没有问题，至少目前没发现问题。
(with-eval-after-load 'org
  ;; (add-hook 'org-mode-hook 'visual-line-mode)
  )

(use-package whitespace-cleanup-mode    ; Cleanup whitespace in buffers
  :disabled t
  :ensure t
  :bind (("C-c t c" . whitespace-cleanup-mode)
         ("C-c x w" . whitespace-cleanup))
  :init (dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
          (add-hook hook #'whitespace-cleanup-mode))
  ;; :diminish whitespace-cleanup-mode
  )

(use-package subword                    ; Subword/superword editing
  :defer t
  ;; :diminish subword-mode
  )

(use-package adaptive-wrap              ; Choose wrap prefix automatically
  :disabled t
  :ensure t
  :defer t
  :init (add-hook 'visual-line-mode-hook #'adaptive-wrap-prefix-mode))

(use-package avy
  :disabled t
  :ensure t
  :bind (("M-g c" . avy-goto-char)
         ("M-g l" . avy-goto-line))
  :config
  (with-eval-after-load "isearch"
    (define-key isearch-mode-map (kbd "C-'") #'avy-isearch)))

(use-package pin :disabled t)

(use-package ace-link
  :ensure t
  :init (ace-link-setup-default))

(use-package zop-to-char                ; alternative to `zap-to-char'
  :ensure t
  ;; TODO: Make a lighter version (I just want to move the point)
  ;; :bind ("M-z" . zop-to-char)
  :defer t)

(use-package easy-kill                  ; Easy killing and marking on C-w
  :disabled t
  :ensure t
  :bind (([remap kill-ring-save] . easy-kill) ; M-w
         ([remap mark-sexp]      . easy-mark) ; C-M-SPC
         ))

(use-package expand-region              ; Expand region by semantic units
  :disabled t
  :ensure t
  :bind ("C-=" . er/expand-region))

(use-package drag-stuff
  :disabled t
  :defer t
  :ensure t)

(use-package align                      ; Align text in buffers
  :bind (("C-c A a" . align)
         ("C-c A c" . align-current)
         ("C-c A r" . align-regexp)))

(use-package mark-align                 ; Align visualized (via Marking)
  :commands mark-align-mode)

(use-package multiple-cursors           ; Edit text with multiple cursors
  :disabled t
  :ensure t
  :bind (("C-c o e"     . mc/mark-more-like-this-extended)
         ("C-c o n"     . mc/mark-next-like-this)
         ("C-c o p"     . mc/mark-previous-like-this)
         ("C-c o l"     . mc/edit-lines)
         ("C-c o C-a"   . mc/edit-beginnings-of-lines)
         ("C-c o C-e"   . mc/edit-ends-of-lines)
         ("C-c o h"     . mc/mark-all-like-this-dwim)
         ("C-c o C-s"   . mc/mark-all-in-region)))

(use-package undo-tree                  ; Branching undo
  :ensure t
  :diminish undo-tree-mode
  :config (global-undo-tree-mode))

(use-package nlinum                     ; Line numbers in display margin
  :ensure t
  :bind (("C-c t l" . nlinum-mode)))


;;; Whitespace - Highlight and Manage Whitespaces

(use-package whitespace                 ; Highlight bad whitespace (tab)
  :diminish " Whitespace"
  ;; TODO: Consider turn on this mode by default
  :bind ("C-c t w" . whitespace-mode)
  :config
  ;; Specify which kind of blank is visualized
  (setq whitespace-style
        '(face
          trailing
          ;; empty lines at beginning and/or end of buffer
          ;; empty
          ;; line is longer `fill-column'
          lines-tail
          ;; If `indent-tabs-mode' on, visualize spaces at the beginning of the
          ;; line, otherwise, visualize tabs.
          indentation
          ;; Visualize TAB
          tab-mark))
  ;; Use `fill-column'
  (setq whitespace-line-column nil))

;; Useful commands to manage whitespace, tab, newline:
;; `whitespace-cleanup'
;; `delete-trailing-whitespace'
;; `just-one-space'
;; `cycle-spacing'
;; `delete-blank-lines'


;;; Enable & Disable some commands

(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)
(put 'narrow-to-defun 'disabled nil)

(put 'view-hello-file
     'disabled "I mistype C-h h a lot and it is too slow to block Emacs")

(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

(put 'timer-list 'disabled nil)


;;; Navigation and scrolling

;; (setq scroll-preserve-screen-position 'always)

(setq scroll-error-top-bottom t         ; Move to beg/end of buffer before
                                        ; signalling an error
      scroll-conservatively 10          ; Smooth Scrolling
      )

;; These settings make trackpad scrolling on OS X much more predictable
;; and smooth
(setq mouse-wheel-progressive-speed nil
      mouse-wheel-scroll-amount '(1))

;; (bind-key* "C-M-p" #'scroll-up-line)
;; (bind-key* "C-M-n" #'scroll-down-line)
;; Use `C-M-l' instead of twice `C-l' for a better view

(use-package page-break-lines           ; Turn page breaks into lines
  :ensure t
  :diminish page-break-lines-mode
  :defer t
  :preface
  (defun chunyang-add-hooks (hooks funcs &optional append local)
    (dolist (hook hooks)
      (dolist (func funcs)
        (add-hook hook func append local))))

  (defun chunyang-remove-hooks (hooks funcs &optional local)
    (dolist (hook hooks)
      (dolist (func funcs)
        (remove-hook hook func local))))
  :init
  (chunyang-add-hooks
   '(prog-mode-hook compilation-mode-hook outline-mode-hook help-mode-hook)
   '(page-break-lines-mode)))

(use-package outline                    ; Navigate outlines in buffers
  ;; TODO: Read (info "(emacs) Outline Mode") to learn this mode
  ;; if it is useful, consider making helm support.
  :disabled t
  :diminish outline-minor-mode
  :config (dolist (hook '(text-mode-hook prog-mode-hook))
            (add-hook hook #'outline-minor-mode)))

(use-package imenu
  :defer t
  :config)


;;; Search
;; | Command     | Note                            |
;; |-------------+---------------------------------|
;; | grep        | grep                            |
;; | lgrep       | grep + shell pattern for files  |
;; | find-grep   | find -exec grep                 |
;; | rgrep       | like find-grep but filter files |
;; | zgrep       | zgrep (search compressed file)  |
;; | vc-git-grep | git-grep                        |
;;
;; See also (info "(emacs) Grep Searching")

(use-package grep
  :defer t
  :config
  (nconc grep-find-ignored-files
         '("TAGS" "GTAGS" "GRTAGS" "GSYMS" "GPATH" "GTAGSROOT"))
  (use-package wgrep :ensure t :defer t))

;; Notes that isearch is not a package and it is loaded from the very
;; beginning
(use-package isearch
  :no-require t
  :defer t
  :preface
  (setq isearch-allow-scroll t)

  (defun chunyang-isearch-mode-setup ()
    "If the region is on, use it as initial search string.
Intended to be added to `isearch-mode-hook'."
    ;; Note that the text of the region can be an invalid regexp
    (when (use-region-p)
      (let ((beg (region-beginning))
            (end (region-end)))
        (deactivate-mark)
        (goto-char beg)
        (isearch-yank-internal (lambda () end)))))

  (add-hook 'isearch-mode-hook #'chunyang-isearch-mode-setup))

(use-package re-builder
  :defer t
  :config
  ;; Escape 的工作就交给 Emacs 了
  (setq reb-re-syntax 'string))

(use-package anzu                       ; Position/matches count for isearch
  :disabled t
  :ensure t
  :diminish anzu-mode
  :init (global-anzu-mode)
  :config
  :config
  (setq anzu-replace-to-string-separator " => ")
  (bind-key "M-%" 'anzu-query-replace)
  (bind-key "C-M-%" 'anzu-query-replace-regexp))

;; TODO: Consider adding `:todo' keyword to `use-package', just for some fun,
;;       it's ok that it's not necessary and useful
;; TODO: Errors on {her,his} -> chunyang
(use-package plur
  :ensure t
  :load-path "~/src/plur"
  :bind ("C-c M-%" . plur-query-replace)
  :config (define-key isearch-mode-map "\M-{" #'plur-isearch-query-replace))

(use-package region-state
  :ensure t
  :commands region-state-mode
  :init (region-state-mode))

(use-package swap-regions
  :ensure t
  :bind ("C-c C-t" . swap-regions)
  :commands swap-regions-mode
  :init (swap-regions-mode))

(use-package clear-text
  :disabled t
  :load-path "~/src/clear-text.el"
  :commands (clear-text-mode global-clear-text-mode))

(use-package pinyin-search
  :ensure t
  :defer t)


;;; Highlight

(use-package hl-line
  :bind ("C-c t L" . hl-line-mode))

(use-package paren                      ; Highlight paired delimiters
  :init (show-paren-mode))

(use-package rainbow-delimiters         ; Highlight delimiters by depth
  :ensure t
  :defer t
  :init (add-hook 'emacs-lisp-mode-hook #'rainbow-delimiters-mode))

(use-package hl-todo
  :ensure t
  :defer t
  :init
  (add-hook 'prog-mode-hook #'hl-todo-mode)
  (add-hook 'yaml-mode-hook #'hl-todo-mode)
  :config
  (add-to-list 'hl-todo-keyword-faces '("IDEA" . "#d0bf8f")))

(use-package color-identifiers-mode
  :ensure t
  :diminish color-identifiers-mode
  :bind ("C-c t c" . global-color-identifiers-mode)
  ;; Need to save my eyes
  ;; :init (add-hook 'after-init-hook #'global-color-identifiers-mode)
  )

(use-package highlight-numbers          ; Fontify number literals
  :disabled t
  :ensure t
  :config
  (add-hook 'prog-mode-hook #'highlight-numbers-mode))

(use-package highlight-symbol           ; Highlighting and commands for symbols
  :disabled t
  :ensure t
  :diminish highlight-symbol-mode
  :init
  ;; Navigate occurrences of the symbol under point with M-n and M-p
  (add-hook 'prog-mode-hook #'highlight-symbol-nav-mode)
  ;; Highlight symbol occurrences
  (add-hook 'prog-mode-hook #'highlight-symbol-mode)
  :config
  (setq highlight-symbol-on-navigation-p t))

(use-package rainbow-mode               ; Fontify color values in code
  :ensure t
  :diminish rainbow-mode
  :defer t
  :init (add-hook 'css-mode-hook #'rainbow-mode))

(use-package hl-issue-id
  :disabled t
  :load-path "~/src/emacs-hl-issue-id"
  :config (global-hl-issue-id-mode))


;;; Skeletons, completion and expansion

(use-package abbrev                     ; For fixing typo only for now
  :disabled t
  :defer t
  :init
  (setq only-global-abbrevs t)
  ;; Enable this mode globally
  (setq-default abbrev-mode t)
  :diminish abbrev-mode)

(use-package hippie-exp                 ; Powerful expansion and completion
  :bind ([remap dabbrev-expand]  . hippie-expand)
  :config
  (setq hippie-expand-try-functions-list
        '(
          ;; Try to expand word "dynamically", searching the current buffer.
          try-expand-dabbrev
          ;; Try to expand word "dynamically", searching all other buffers.
          try-expand-dabbrev-all-buffers
          ;; Try to expand word "dynamically", searching the kill ring.
          try-expand-dabbrev-from-kill
          ;; Try to complete text as a file name, as many characters as unique.
          try-complete-file-name-partially
          ;; Try to complete text as a file name.
          try-complete-file-name
          ;; Try to expand word before point according to all abbrev tables.
          try-expand-all-abbrevs
          ;; Try to complete the current line to an entire line in the buffer.
          try-expand-list
          ;; Try to complete the current line to an entire line in the buffer.
          try-expand-line
          ;; Try to complete as an Emacs Lisp symbol, as many characters as
          ;; unique.
          try-complete-lisp-symbol-partially
          ;; Try to complete word as an Emacs Lisp symbol.
          try-complete-lisp-symbol)))

(use-package company                    ; Graphical (auto-)completion
  :ensure t
  :diminish company-mode
  :commands company-complete
  :init (global-company-mode)
  :config
  ;; Use Company for completion C-M-i
  (bind-key [remap completion-at-point] #'company-complete company-mode-map)
  ;; M-h/c-h/F1 to display doc in help buffer, C-w to show location
  (define-key company-active-map "\M-h" #'company-show-doc-buffer)
  (setq company-tooltip-align-annotations t
        company-minimum-prefix-length 2
        ;; Easy navigation to candidates with M-<n>
        company-show-numbers t))

(use-package auto-complete
  :disabled t
  :ensure t
  :config
  (ac-config-default)
  (setq ac-auto-show-menu 0.3
        ;; ac-delay 0.1
        ac-quick-help-delay 0.5)
  (use-package ac-ispell
    :ensure t
    :config
    ;; Completion words longer than 4 characters
    (setq ac-ispell-requires 4
          ac-ispell-fuzzy-limit 2)

    (eval-after-load "auto-complete"
      '(progn
         (ac-ispell-setup)))

    (add-hook 'git-commit-mode-hook 'ac-ispell-ac-setup)
    (add-hook 'mail-mode-hook 'ac-ispell-ac-setup)))

(use-package yasnippet
  :disabled t
  :ensure t
  :diminish yas-minor-mode
  :config (yas-global-mode))


;;; Spelling and syntax checking

(use-package flyspell
  :init
  ;; (add-hook 'text-mode-hook #'flyspell-mode)
  ;; (add-hook 'prog-mode-hook #'flyspell-prog-mode)
  ;; Magit commit message
  (add-hook 'git-commit-mode-hook #'flyspell-mode)
  ;; VC commit message
  (add-hook 'log-edit-mode-hook #'flyspell-mode)
  ;; Email
  (add-hook 'message-mode-hook #'flyspell-mode)
  (use-package ispell
    :defer t
    :init
    (setq ispell-program-name "aspell"
          ispell-extra-args '("--sug-mode=ultra")))
  :bind ("C-c t s" . flyspell-mode)
  :config
  (unbind-key "C-."   flyspell-mode-map)
  (unbind-key "C-M-i" flyspell-mode-map)
  (unbind-key "C-;"   flyspell-mode-map)
  (use-package flyspell-popup
    :ensure t
    :config
    (define-key flyspell-mode-map [?\C-.] #'flyspell-popup-correct)
    (add-hook 'flyspell-mode-hook #'flyspell-popup-auto-correct-mode)))

;; NOTE: Goto https://www.languagetool.org/ to install the command
;; line tool.  Java (JDK) is required.
(use-package langtool                ; English Style and Grammar Check
  :ensure t
  :defer t
  :config
  (setq langtool-language-tool-jar
        (car (nreverse (file-expand-wildcards
                        "~/src/LanguageTool-*/languagetool-commandline.jar")))))

(use-package checkdoc
  :disabled t                           ; Not working anyway
  :config (setq checkdoc-arguments-in-order-flag nil
                checkdoc-force-docstrings-flag nil))

(use-package flycheck
  :ensure t
  :bind (("C-c t f" . global-flycheck-mode))
  :config

  (setq flycheck-emacs-lisp-load-path 'inherit)

  (defun chunyang-flycheck-toggle-checkdoc ()
    (interactive)
    (setq-local flycheck-disabled-checkers
                (if (memq 'emacs-lisp-checkdoc flycheck-disabled-checkers)
                    (delq 'emacs-lisp-checkdoc flycheck-disabled-checkers)
                  (cons 'emacs-lisp-checkdoc flycheck-disabled-checkers)))
    (when flycheck-mode
      (flycheck-mode 'toggle)
      (flycheck-mode 'toggle)))

  (use-package flycheck-pos-tip           ; Show Flycheck messages in popups
    :disabled t
    :ensure t
    :config (setq flycheck-display-errors-function
                  #'flycheck-pos-tip-error-messages))

  (use-package flycheck-color-mode-line
    :disabled t
    :ensure t
    :config
    (eval-after-load "flycheck"
      (add-hook 'flycheck-mode-hook 'flycheck-color-mode-line-mode))))


;;; Markup languages

;; TODO: Fontify markdown link like org, see `org-descriptive-links',
;; `orglink', and (elisp) Font Lock Mode.
(use-package markdown-mode
  :ensure t
  :defer t
  :preface
  (defun chunyang-markdown-insert-link (title link)
    (interactive
     (let ((title (read-string "Title: "))
           (link  (read-string "Link: ")))
       (list title link)))
    (insert (format "[%s](%s)" title link)))
  ;; :mode ("README\\.md\\'" . gfm-mode)
  :config
  (setq markdown-command "pandoc --standalone -f markdown -t html"))

(use-package yaml-mode :ensure t :defer t)


;;; Programming utilities

;; `glasses-mode' -- 把 areYouReady 显示成 are_You_Ready
;; `subword-mode' -- 把 StudlyCapsIdentifiers 当作一个 word
;; `superword-mode' -- 把 this_is_a_symbol 当作一个 word
;; `hs-minor-mode' -- Hideshow / 折叠、隐藏

(use-package eldoc
  :defer t
  :config
  ;; Alternative to `eldoc-minibuffer-message'
  (defun chunyang-eldoc-header-line-message (format-string &rest args)
    (setq header-line-format
          (apply #'format format-string args))
    (force-mode-line-update))

  ;; (setq eldoc-message-function #'chunyang-eldoc-header-line-message)
  )

(cl-defun chunyang-project-root (&optional (dir default-directory))
  "Return project root in DIR, if no project is found, return DIR."
  (or (cdr (project-current nil dir))
      dir))

(use-package compile
  :bind (("C-x c" . compile))
  :preface

  (defun chunyang-ansi-color-compilation-buffer ()
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region compilation-filter-start (point))))

  ;; (defvar chunyang-compilation-root nil)
  ;; (defun chunyang-compilation-setup ()
  ;;   (setq chunyang-compilation-root (chunyang-project-root)))
  ;; (defun chunyang-compilation-save-buffers-predicate ()
  ;;   (file-in-directory-p (buffer-file-name) chunyang-compilation-root))

  :config
  ;; Colorize ansi escape color code
  (add-hook 'compilation-filter-hook 'chunyang-ansi-color-compilation-buffer)

  ;; FIXME: This is not working on 25.1.1 from macOS
  ;; Only ask for saving files under current project
  ;; (setq compilation-process-setup-function 'chunyang-compilation-setup)
  ;; (setq compilation-save-buffers-predicate
  ;;       'chunyang-compilation-save-buffers-predicate)

  (setq compilation-always-kill t
        compilation-scroll-output 'first-error))

(use-package quickrun
  :ensure t :defer t)

(use-package prog-mode
  :bind ("C-c t p" . prettify-symbols-mode)
  ;; TODO: I have some font issue, so disalbe it for now
  ;; :init (add-hook 'emacs-lisp-mode-hook #'prettify-symbols-mode)
  ;; :init (global-prettify-symbols-mode)
  )

(use-package bug-reference              ; buttonize bug references like issue #5
  :disabled t                           ; XXX Disable to reduce init time
  ;; Set `bug-reference-url-format' and `bug-reference-bug-regexp' per
  ;; buffer/file/project.
  ;;
  ;; Example setting:
  ;; bug-reference-url-format: "https://github.com/xuchunyang/emacs.d/issues/%s"
  ;; bug-reference-bug-regexp: "\\(issue #\\)\\([0-9]+\\)"
  ;;
  ;; Notes that that github issue url works for pull request as well,
  ;; since github redirects /issues/123 to /pull/123 if that is a pull
  ;; request.
  ;;
  ;; To use, run `bug-reference-prog-mode' or `bug-reference-mode' via
  ;; M-x or Local Variable or Hook like the following:
  ;;
  ;; (add-hook 'prog-mode-hook #'bug-reference-prog-mode)
  ;; (add-hook 'magit-log-mode #'bug-reference-mode)
  ;;
  ;; Loading at start-up to make sure Emacs knows
  ;; `bug-reference-url-format' and `bug-reference-bug-regexp' are
  ;; *safe* local variable
  ;; :defer t
  )

(use-package nocomments-mode            ; Hide Comments
  :ensure t
  :defer t)


;;; Generic Lisp

(use-package paredit                    ; Balanced sexp editing
  :ensure t
  :diminish paredit-mode
  :commands paredit-mode
  :init
  (add-hook 'lisp-mode-hook 'paredit-mode)
  (add-hook 'emacs-lisp-mode-hook 'paredit-mode)
  :config
  (unbind-key "M-r" paredit-mode-map) (bind-key "M-R" #'paredit-raise-sexp  paredit-mode-map)
  (unbind-key "M-s" paredit-mode-map) (bind-key "M-S" #'paredit-splice-sexp paredit-mode-map)
  (unbind-key "C-j" paredit-mode-map)
  (unbind-key "M-q" paredit-mode-map)
  (unbind-key "M-?" paredit-mode-map)
  (unbind-key "M-;" paredit-mode-map)

  (use-package paredit-menu
    :ensure t
    :commands menubar-paredit))

(use-package adjust-parens              ; TODO: Try it!!!
  :disabled t
  :ensure t
  :config (add-hook 'emacs-lisp-mode-hook #'adjust-parens-mode))


;;; Emacs Lisp

(use-package elisp-mode
  :defer t
  :preface
  (defun chunyang-elisp-function-or-variable-quickhelp (symbol)
    "Display a short documentation of function or variable using `popup'.

See also `describe-function-or-variable'."
    (interactive
     (let* ((v-or-f (variable-at-point))
            (found (symbolp v-or-f))
            (v-or-f (if found v-or-f (function-called-at-point))))
       (list v-or-f)))
    (if (not (and symbol (symbolp symbol)))
        (message "You didn't specify a function or variable")
      (let* ((fdoc (when (fboundp symbol)
                     (or (documentation symbol t) "Not documented.")))
             (fdoc-short (and (stringp fdoc)
                              (substring fdoc 0 (string-match "\n" fdoc))))
             (vdoc (when  (boundp symbol)
                     (or (documentation-property symbol 'variable-documentation t)
                         "Not documented as a variable.")))
             (vdoc-short (and (stringp vdoc)
                              (substring vdoc 0 (string-match "\n" vdoc)))))
        (and (require 'popup nil 'no-error)
             (popup-tip
              (or
               (and fdoc-short vdoc-short
                    (concat fdoc-short "\n\n"
                            (make-string 30 ?-) "\n" (symbol-name symbol)
                            " is also a " "variable." "\n\n"
                            vdoc-short))
               fdoc-short
               vdoc-short)
              :margin t)))))

  :config
  (bind-key "C-h C-." #'chunyang-elisp-function-or-variable-quickhelp)
  (bind-key "M-:"     #'pp-eval-expression)
  (bind-key "C-c t d" #'toggle-debug-on-error)

  (let ((sym-regexp (or (bound-and-true-p lisp-mode-symbol-regexp)
                        "\\(?:\\sw\\|\\s_\\|\\\\.\\)+")))
    (add-to-list
     'lisp-imenu-generic-expression
     (list "Packages"
           (concat "^\\s-*("
                   (eval-when-compile
                     (regexp-opt '("use-package" "require") t))
                   "\\s-+\\(" sym-regexp "\\)")
           2))
    (add-to-list
     'lisp-imenu-generic-expression
     (list "Hydras"
           (concat "^\\s-*("
                   (eval-when-compile
                     (regexp-opt '("defhydra") t))
                   "\\s-+\\(" sym-regexp "\\)")
           2)))

  (when (version< emacs-version "25")
    (add-hook 'emacs-lisp-mode-hook #'eldoc-mode)))

(use-package aggressive-indent
  :disabled t
  :ensure t
  :defer t
  :diminish aggressive-indent-mode
  :init
  (add-hook 'emacs-lisp-mode-hook #'aggressive-indent-mode))

(use-package el-search
  :if (version< "25" emacs-version)
  :ensure t
  :defer t
  :init
  (with-eval-after-load 'elisp-mode
    (define-key emacs-lisp-mode-map [(control ?S)] #'el-search-pattern)
    (define-key emacs-lisp-mode-map [(control ?%)] #'el-search-query-replace)
    (define-key lisp-interaction-mode-map [(control ?S)] #'el-search-pattern)
    (define-key lisp-interaction-mode-map [(control ?%)] #'el-search-query-replace))

  (with-eval-after-load 'isearch
    (define-key isearch-mode-map [(control ?S)] #'el-search-search-from-isearch)
    (define-key isearch-mode-map [(control ?%)] #'el-search-replace-from-isearch))
  (with-eval-after-load 'el-search
    (define-key el-search-read-expression-map [(control ?S)] #'exit-minibuffer)))

(use-package chunyang-elisp
  :after elisp-mode
  :defer t
  :config
  (bind-keys :map emacs-lisp-mode-map
             ("C-j" . chunyang-eval-print-last-sexp)
             ("C-," . chunyang-macroexpand-print-last-sexp)
             :map lisp-interaction-mode-map
             ("C-j" . chunyang-eval-print-last-sexp)
             ("C-," . chunyang-macroexpand-print-last-sexp))
  (with-eval-after-load 'aggressive-indent
    (push 'chunyang-eval-print-last-sexp
          aggressive-indent-protected-commands)
    (push 'chunyang-macroexpand-print-last-sexp
          aggressive-indent-protected-commands)))

(use-package chunyang-package
  :commands chunyang-package-homepage)

(use-package ielm
  :defer t
  :config
  (add-hook 'ielm-mode-hook #'enable-paredit-mode))

(use-package macrostep
  :ensure t
  :bind ("C-c e" . macrostep-expand))

(use-package pcache              :ensure t :defer t)
(use-package persistent-soft     :ensure t :defer t)
(use-package log4e               :ensure t :defer t)
(use-package alert               :ensure t :defer t)

(use-package bug-hunter                 ; This is good
  :disabled t
  :ensure t :defer t)

(use-package debbugs                    ; Interface to GNU Bugs
  :ensure t
  :defer t
  :preface
  ;; TODO: Fontify #1234 (make it clickable) in certain modes
  (defun chunyang-open-emacs-bug (id)
    "Open emacs bug report in browser, the bug id looks like Bug#25942."
    (interactive (list
                  (or (number-at-point)
                      (and (looking-at "#\\([0-9]*\\)")
                           (string-to-number (match-string 1)))
                      (read-number "Bug Id: "))))
    (let ((url
           (format "https://debbugs.gnu.org/cgi/bugreport.cgi?bug=%s"
                   id)))
      (message "Opening %s ..." (propertize url 'face 'link))
      (browse-url url))))

(use-package hydra
  :ensure t
  :defer t)

(use-package debug
  :defer t
  :config
  (defhydra hydra-debugger-menu ()
    "Debug"
    ("c" debugger-continue "Continue")
    ("e" debugger-eval-expression "Eval")
    ("v" debugger-toggle-locals "Display local Variable"))

  (define-key debugger-mode-map "." 'hydra-debugger-menu/body))

;; TODO Add (info "(elisp) Edebug")

(use-package nameless
  :ensure t
  :defer t)

(use-package package-lint               ; Check Compatibility
  :ensure t
  :defer t)


;;; Help & Info

(defun chunyang-info-elisp-manual ()
  (interactive)
  (info "elisp"))

(defun chunyang-info-org-manual ()
  (interactive)
  (info "org"))

(bind-key "C-h C-k" #'find-function-on-key)
;; C-h r `info-emacs-manual'
(bind-key "C-h E"   #'chunyang-info-elisp-manual)
(bind-key "C-h O"   #'chunyang-info-org-manual)

(use-package help-mode
  :preface
  (defun view-help-buffer ()
    "View the `*Help*' buffer."
    (interactive)
    (pop-to-buffer (help-buffer)))
  (defun chunyang-clear-messages-buffer ()
    "Delete the contents of the *Messages* buffer."
    (interactive)
    (with-current-buffer "*Messages*"
      (let ((inhibit-read-only t))
        (erase-buffer))))
  (defun help-info-lookup-symbol ()
    (interactive)
    (when-let ((symbol (cadr help-xref-stack-item)))
      (info-lookup-symbol symbol)))
  (defun chunyang-describe-symbol-at-point ()
    "Like `describe-symbol' but doesn't query always."
    (interactive)
    (require 'help-mode)
    (let* ((is-symbol-p
            (lambda (vv)
              (cl-some (lambda (x) (funcall (nth 1 x) vv))
                       describe-symbol-backends)))
           (sym
            (or (let ((it (intern (current-word))))
                  (when (funcall is-symbol-p it)
                    it))
                (completing-read
                 "Describe symbol: "
                 obarray
                 is-symbol-p
                 t))))
      (describe-symbol sym)))
  :bind (("C-h ." . chunyang-describe-symbol-at-point)
         ("C-h h" . view-help-buffer)
         :map help-mode-map
         ("b" . help-go-back)
         ("f" . help-go-forward)
         ("i" . help-info-lookup-symbol)))

(use-package info-look
  :defer t
  :config
  (info-lookup-add-help
   :mode 'emacs-lisp-mode
   :regexp "[^][()`'‘’,\" \t\n]+"
   :doc-spec '(("(emacs)Command Index"             nil "['`‘]\\(M-x[ \t\n]+\\)?" "['’]") ;
               ("(emacs)Variable Index"            nil "['`‘]" "['’]")
               ("(elisp)Index"                     nil "^ -+ .*: " "\\( \\|$\\)")
               ;; cl-lib
               ("(cl) Function Index"              nil "^ -+ .*: " "\\( \\|$\\)")
               ("(cl) Variable Index"              nil "^ -+ .*: " "\\( \\|$\\)")
               ;; Org
               ("(org) Variable Index"             nil "['`‘]" "['’]")
               ("(org) Command and Function Index" nil "['`‘(]" "['’)]")
               ;; Magit
               ("(magit) Command Index"            nil "(['`‘]" "['’])")
               ("(magit) Variable Index"           nil "^ -+ .*: " "\\( \\|$\\)"))))

(use-package info
  :defer t
  :config
  ;; NOTE: MacPorts doesn't take care of info documentation, thus
  ;; don't forget to install them via install-info(1) manually

  ;; Prefer MacPorts's Info Manual over system builtin
  (when *is-mac*
    (let ((pos (1- (min (seq-position Info-directory-list "/usr/local/share/info/")
                        (seq-position Info-directory-list "/usr/share/info/")))))
      ;; Let's insert a new path at POS
      (let ((tail (nthcdr pos Info-directory-list)))
        (setcdr tail (cons "/opt/local/share/info/" (cdr tail))))))

  ;; IDEA Track info browse history
  ;; (defvar chunyang-Info-visited-nodes nil)
  ;; (defun chunyang-Info-track-history ()
  ;;   (list (file-name-nondirectory Info-current-file)
  ;;         Info-current-node)
  ;;   (message "todo..."))
  ;; (add-hook 'Info-selection-hook 'chunyang-Info-track-history)

  ;; Get HTML link
  ;; (emacs) Echo Area
  ;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Echo-Area.html
  ;;
  ;; (elisp) The Echo Area
  ;; https://www.gnu.org/software/emacs/manual/html_node/elisp/The-Echo-Area.html
  ;; TODO Support even more Info manuals
  ;; TODO Convert html url to info node
  (defvar chunyang-Info-html-alist
    '(
      ;; Special cases come first
      ("org"  . "http://orgmode.org/manual/%s")
      ("find" . "https://www.gnu.org/software/findutils/manual/html_node/find_html/%s")
      ("standards" . "https://www.gnu.org/prep/standards/html_node/%s")
      ("magit" . "https://magit.vc/manual/magit/%s")
      ("slime" . "https://www.common-lisp.net/project/slime/doc/html/%s")
      ;; Haha, just for some fun
      ("geiser" . (lambda (_)
                    ;; (info "(geiser) First aids")
                    ;; http://www.nongnu.org/geiser/geiser_3.html#First-aids
                    (if (string=  Info-current-node "Top")
                        "http://www.nongnu.org/geiser/"
                      (let ((node (replace-regexp-in-string " " "-" Info-current-node))
                            (number (save-excursion
                                      (goto-char (point-min))
                                      (re-search-forward "^[0-9]")
                                      (match-string 0))))

                        (format "http://www.nongnu.org/geiser/geiser_%s.html#%s" number node)))))
      ;; Hmm, macOS (or MacPorts) doesn't like GNU either
      ("gawk" . "https://www.gnu.org/software/tar/manual/html_node/%s")
      ;; GNU info documents.  Taken from my memory or see https://www.gnu.org/software/
      (("awk" "sed" "tar" "make" "m4" "grep" "coreutils" "guile" "screen"
        "libc" "make" "gzip" "diffutils" "wget" "grub") .
        (lambda (software)
          (format "https://www.gnu.org/software/%s/manual/html_node/%%s" software)))
      ("gcc-5" . "https://gcc.gnu.org/onlinedocs/gcc/%s")
      (("gdb" "stabs") .
       (lambda (software)
         (format "https://sourceware.org/gdb/onlinedocs/%s/%%s" software)))
      ;; Emacs info documents.  Taken from `org-info-emacs-documents'
      (("ada-mode" "auth" "autotype" "bovine" "calc" "ccmode" "cl" "dbus" "dired-x"
        "ebrowse" "ede" "ediff" "edt" "efaq-w32" "efaq" "eieio" "eintr" "elisp"
        "emacs-gnutls" "emacs-mime" "emacs" "epa" "erc" "ert" "eshell" "eudc" "eww"
        "flymake" "forms" "gnus" "htmlfontify" "idlwave" "ido" "info" "mairix-el"
        "message" "mh-e" "newsticker" "nxml-mode" "octave-mode" "org" "pcl-cvs"
        "pgg" "rcirc" "reftex" "remember" "sasl" "sc" "semantic" "ses" "sieve"
        "smtpmail" "speedbar" "srecode" "todo-mode" "tramp" "url" "vip" "viper"
        "widget" "wisent" "woman") .
        (lambda (package)
          (format "https://www.gnu.org/software/emacs/manual/html_node/%s/%%s" package)))))

  (defun chunyang-org-info-map-anchor-url (node)
    "Return URL associated to Info NODE."
    (require 'org)                      ; for `org-trim'
    ;; See (info "(texinfo) HTML Xref Node Name Expansion") for the
    ;; expansion rule
    (let* ((node (replace-regexp-in-string "[ \t\n\r]+" " " (org-trim node)))
           (node (mapconcat (lambda (c)
                              (if (string-match "[a-zA-Z0-9 ]" (string c))
                                  (string c)
                                (format "_%04x" c)))
                            (string-to-list node) ""))
           (node (replace-regexp-in-string " " "-" node))
           (url (if (string= node "")
                    ""
                  (if (string-match "[0-9]" (substring node 0 1))
                      (concat "g_t" node)
                    node))))
      url))
  (defun chunyang-Info-get-current-node-html ()
    (cl-assert (eq major-mode 'Info-mode))
    (let* ((file (file-name-nondirectory Info-current-file))
           (node Info-current-node)
           (html (if (string= node "Top")
                     ""
                   (concat (chunyang-org-info-map-anchor-url node) ".html")))
           (baseurl (loop for (k . v) in chunyang-Info-html-alist
                          when (cond ((stringp k) (equal file k))
                                     ((listp k) (member file k)))
                          return (if (stringp v) v (funcall v file)))))
      ;; Maybe it's a good idea to assuming GNU softwares in this case
      (cl-assert baseurl nil "Unsupported info document '%s'" file)
      (format baseurl html)))

  ;; TODO: Consider using `defhydra' or `helm' for these actions
  ;; Copy: (elisp) Cons Cells
  ;; Copy: (info "(elisp) Cons Cells")
  ;; Copy: https://www.gnu.org/software/emacs/manual/html_node/elisp/Cons-Cells.html
  ;; Open: https://www.gnu.org/software/emacs/manual/html_node/elisp/Cons-Cells.html
  ;; Copy: Markdown: ...
  ;; Copy: Org: ...

  (defun chunyang-Info-copy-current-node-html ()
    (interactive)
    (let ((url (chunyang-Info-get-current-node-html)))
      (kill-new url)
      (message "Copied: %s" url)))

  (defun chunyang-Info-browse-current-node-html ()
    (interactive)
    (let ((url (chunyang-Info-get-current-node-html)))
      (browse-url url)))

  (defun chunyang-Info-markdown-current-node-html (&optional arg)
    "ARG will be passed to `Info-copy-current-node-name'."
    (interactive "P")
    (let ((description (Info-copy-current-node-name arg))
          (link (chunyang-Info-get-current-node-html)))
      (let ((markdown (format "[%s](%s)" description link)))
        (kill-new markdown)
        (message "Copied: %s" markdown))))

  (defun chunyang-Info-org-current-node-html (&optional arg)
    "ARG will be passed to `Info-copy-current-node-name'."
    (interactive "P")
    (let ((description (Info-copy-current-node-name arg))
          (link (chunyang-Info-get-current-node-html)))
      (let ((org (format "[[%s][%s]]" link description)))
        (kill-new org)
        (message "Copied: %s" org))))

  (bind-key "C" 'chunyang-Info-copy-current-node-html Info-mode-map))

(use-package cus-edit
  :preface
  (defun chunyang/custom-mode-describe-symbol-at-point ()
    (interactive)
    (require 'info-look)
    (let ((symbol (intern (downcase (info-lookup-guess-custom-symbol)))))
      (describe-symbol symbol)))
  :bind (:map custom-mode-map
              ("C-h ." . chunyang/custom-mode-describe-symbol-at-point)))

(use-package command-log-mode           ; BUG: Create a new empty buffer and
                                        ; insert some text, should blame
                                        ; function added to post-self-insert-hook
  :disabled t
  :ensure t)


;;; Version Control

(use-package diff-mode
  :defer t
  :config
  ;; I used this key for M-o (`chunyang-ace-window')
  (unbind-key "M-o" diff-mode-map))

(use-package magit
  :ensure t
  :bind (("C-x g"   . magit-status)
         ("C-x M-g" . magit-dispatch-popup))
  ;; :init (global-git-commit-mode)
  :config
  ;; Save files before executing git command for me
  (setq magit-save-repository-buffers 'dontask))

(use-package vc
  :defer t
  :init
  ;; Don't ask me again
  (setq vc-follow-symlinks t))

(use-package git-gutter
  :ensure t
  :bind (("C-x G"   . git-gutter-mode)
         ("C-x v n" . git-gutter:next-hunk)
         ("C-x v p" . git-gutter:previous-hunk)
         ("C-x v s" . git-gutter:stage-hunk)
         ("C-x v r" . git-gutter:revert-hunk))
  :config
  (setq git-gutter:handled-backends '(git svn))

  (defun chunyang-git-gutter-count-hunks (beg end)
    (let ((number-of-hunks 0))
      (save-excursion
        (goto-char beg)
        (when (ignore-errors (git-gutter:search-here-diffinfo git-gutter:diffinfos))
          (setq number-of-hunks 1))
        (while (let ((old-pt (point)))
                 (git-gutter:next-hunk 1)
                 (and (> (point) old-pt)
                      (<= (point) end)))
          (setq number-of-hunks (+ 1 number-of-hunks))))
      ;; (message "You have %d changes in the region" number-of-hunks)
      number-of-hunks))

  (defun chunyang-git-gutter-apply-on-region (beg end revert-or-stage)
    (let ((git-gutter:ask-p nil)
          (number-of-hunks (chunyang-git-gutter-count-hunks beg end)))
      (goto-char beg)
      (when (ignore-errors (git-gutter:search-here-diffinfo git-gutter:diffinfos))
        (funcall revert-or-stage)
        (sit-for .3)
        (setq number-of-hunks (- number-of-hunks 1)))
      (dotimes (_ number-of-hunks)
        (git-gutter:next-hunk 1)
        (funcall revert-or-stage)
        (sit-for .3))
      (deactivate-mark)
      (git-gutter:update-all-windows)))

  (defun chunyang-git-gutter-revert-region (beg end)
    (interactive "r")
    (chunyang-git-gutter-apply-on-region beg end 'git-gutter:revert-hunk))

  (defun chunyang-git-gutter-stage-region (beg end)
    (interactive "r")
    (chunyang-git-gutter-apply-on-region beg end 'git-gutter:stage-hunk)))

(use-package diff-hl
  :disabled t
  :ensure t
  :init (global-diff-hl-mode))

(use-package git-messenger
  :ensure t
  :bind ("C-x v P" . git-messenger:popup-message))

(use-package git-timemachine            ; Go back in Git time
  :ensure t
  :bind ("C-x v t" . git-timemachine))

(use-package gitconfig-mode             ; Edit .gitconfig files
  :ensure t
  :defer t)

(use-package gitignore-mode             ; Edit .gitignore files
  :ensure t
  :defer t)


;;; Tools and utilities

(use-package woman
  :defer t
  :config (setq woman-fill-frame t))

(use-package comint
  :defer t
  :config
  ;; Disable auto scroll on RET (like Eshell)
  (setq comint-scroll-show-maximum-output nil))

(use-package atomic-chrome
  :ensure t                             ; To install its dependencies
  :defer 7                              ; since the entry of this
                                        ; package is from Chrome
  :preface
  (defun chunyang-atomic-chrome-server-running-p ()
    (cond ((executable-find "lsof")
           (zerop (call-process "lsof" nil nil nil "-i" ":64292")))
          ((executable-find "netstat")  ; Windows
           (zerop (call-process-shell-command "netstat -aon | grep 64292")))))
  :config
  (setq atomic-chrome-url-major-mode-alist
        '(("github\\.com"        . gfm-mode)
          ("emacs-china\\.org"   . gfm-mode)
          ("stackexchange\\.com" . gfm-mode)
          ("stackoverflow\\.com" . gfm-mode)))

  (defun chunyang-atomic-chrome-mode-setup ()
    (setq header-line-format
          (substitute-command-keys
           "Edit Chrome text area.  Finish \
`\\[atomic-chrome-close-current-buffer]'.")))

  (add-hook 'atomic-chrome-edit-mode-hook #'chunyang-atomic-chrome-mode-setup)

  (if (chunyang-atomic-chrome-server-running-p)
      (message "Can't start atomic-chrome server, because port 64292 is already used")
    (atomic-chrome-start-server)))

(use-package ediff
  :defer t
  :init
  (defun chunyang-dired-ediff (file-a file-b)
    (interactive
     (let ((files (dired-get-marked-files)))
       (if (= (length files) 2)
           (list (car files) (cadr files))
         (let ((file-a (dired-get-filename nil t)))
           (unless file-a
             (setq file-a (read-file-name "File A to compare: ")))
           (list file-a (read-file-name (format "Diff %s with: " file-a)))))))
    (ediff-files file-a file-b))
  :config
  ;; (setq ediff-window-setup-function 'ediff-setup-windows-plain)
  ;; or --unified, more compact context, see
  ;; (info "(diffutils) Unified Format")
  (setq ediff-custom-diff-options "-u"))

(use-package server
  :defer 3
  :config
  (unless (server-running-p) (server-start))

  (defun open-emacs-window ()
    (select-frame-set-input-focus (selected-frame)))

  ;; Hmm, 'C-c C-c' is easier than 'C-x #' to type
  (defun chunyang-server-setup ()
    (unless (key-binding [?\C-c ?\C-c])
      (local-set-key [?\C-c ?\C-c] #'server-edit)))

  (defun chunyang-server-cleanup ()
    (when (eq (key-binding [?\C-c ?\C-c]) 'server-edit)
      (define-key (current-local-map) [?\C-c ?\C-c] nil)))

  (add-hook 'server-switch-hook #'chunyang-server-setup)
  (add-hook 'server-done-hook #'chunyang-server-cleanup))

(use-package gh-md             :ensure t :defer t)

(use-package github-notifier
  :disabled t
  :load-path "~/src/github-notifier.el"
  :commands github-notifier)

(use-package chunyang-github
  :ensure ghub                          ; Dependency
  :commands (helm-chunyang-github-stars
             helm-chunyang-github-repos))

(use-package tramp                      ; Work with remote files
  ;; The entry point is find-file. Examples
  ;;
  ;; /sudo::/etc/shells
  ;; /ssh:xcy@xuchunyang.me:/home/xcy/  or just
  ;; /xuchunyang.me:/home/xcy
  ;; /ftp:hmwzynmu@6MK2JSCNAME.FYVPS.COM:/domains/foo.xuchunyang.me/public_html/
  ;;
  ;; Dired, Magit, Shell (M-x shell /ssh:xuchunyang.me:/bin/bash) and
  ;; Eshell works, while ansi-term doesn't not. See
  ;; (info "(tramp) Remote processes")
  :defer t
  :config
  ;; Disable version control to avoid delays:
  (setq vc-ignore-dir-regexp
        (format "\\(%s\\)\\|\\(%s\\)"
                vc-ignore-dir-regexp
                tramp-file-name-regexp)))

(use-package chunyang-sudo-edit
  :no-require t
  :defer t
  :preface
  ;; Wow, Tramp makes it possible to edit local file as "sudo", see
  ;; (info "(tramp) Default Method")
  (defun chunyang-sudo-edit ()
    (interactive)
    (let ((buf (current-buffer))
          (fn (buffer-file-name))
          (pt (point)))
      (find-file (concat "/sudo::" fn))
      (goto-char pt)
      (kill-buffer buf)))

  (defun chunyang-sudo-edit-notify ()
    "Notify myself when edit a file owned by root.
This should be add to `find-file-hook'."
    (let ((old-msg (current-message)))
      (when (and old-msg
                 (string= old-msg "Note: file is write protected")
                 ;; `chunyang-sudo-edit' doesn't work for remote files
                 ;; for now
                 (not (file-remote-p (buffer-file-name))))
        (message "%s, %s"
                 old-msg
                 "use M-x chunyang-sudo-edit RET to edit as sudo"))))

  :init (add-hook 'find-file-hook #'chunyang-sudo-edit-notify))

(use-package ansible-doc
  :ensure t
  :commands ansible-doc)

(use-package ztree                      ; Diff directories
  ;; TODO: Learn more about this package
  :ensure t
  :defer t)

(use-package lastpass
  :load-path "/Users/xcy/src/lastpass.el"
  :commands helm-lastpass)


;;; Project

;; (use-package projectile :disabled t)


;;; Web & IRC & Email & RSS

;; Just by providing the following, Emacs can already send emails
;;
;; Password is provided in ~/.authinfo file (this file should be encrypted via gpg)
(setq user-full-name       "Chunyang Xu"
      user-mail-address    "mail@xuchunyang.me"
      smtpmail-smtp-server "smtp.exmail.qq.com"
      send-mail-function   'smtpmail-send-it)

(use-package message
  :defer t
  :tips
  ((message-elide-region         . "C-c C-e 省略一段冗长的引用")
   (message-mark-inserted-region . "C-c M-m 给一段文字（常常是代码）加上框"))
  :preface
  (defun chunyang-message-signature ()
    "Setup message signature adaptively."
    (require 'epa-mail)
    (let ((real-recipients (epa-mail-default-recipients)))
      (cond ((member "emacs-orgmode@gnu.org" real-recipients)
             (call-interactively #'org-version))
            ((member "emacs-devel@gnu.org" real-recipients)
             nil)
            (t nil))))
  :config
  ;; don't keep message buffers around
  (setq message-kill-buffer-on-exit t)
  (setq message-directory (locate-user-emacs-file "var/Mail"))
  (setq message-signature 'chunyang-message-signature))

(use-package notmuch
  ;; Installed notmuch from Git on macOS with:
  ;; ./configure && make && sudo make install
  :if *is-mac*
  :load-path "/usr/local/share/emacs/site-lisp"
  :commands notmuch
  :preface
  (defun chunyang-notmuch-update ()
    (interactive)
    (shell-command "notmuch new &")
    (set-process-sentinel
     (get-buffer-process "*Async Shell Command*")
     (lambda (_proc _event)
       (with-current-buffer "*notmuch-hello*"
         (notmuch-refresh-this-buffer)))))
  :config
  ;; 为了搜索中文, 'XAPIAN_CJK_NGRAM' 必须在 'notmuch new' 前设置
  ;; (同样的，不要忘记在给 Shell 也做同样的设置）
  (unless (getenv "XAPIAN_CJK_NGRAM")
    (setenv "XAPIAN_CJK_NGRAM" "1"))

  (bind-key "U" #'chunyang-notmuch-update notmuch-hello-mode-map)

  (setq notmuch-search-oldest-first nil)

  ;; Don't save sent mail locally
  (setq notmuch-fcc-dirs nil)
  
  ;; Don't display notmuch logo, it's invisible in dark theme
  (setq notmuch-show-logo nil)

  ;; Don't enable `visual-line-mode' by default
  (remove-hook 'notmuch-show-hook
               #'notmuch-show-turn-on-visual-line-mode)

  ;; Tell others I am using Notmuch
  (setq notmuch-mua-user-agent-function 'notmuch-mua-user-agent-full))

(use-package ace-link-notmuch
  :ensure ace-link
  :after notmuch
  :config (ace-link-notmuch-setup))

(use-package helm-notmuch
  :ensure t
  :defer t)

(use-package sx
  :ensure t :defer t)

(use-package eww
  :defer t
  :preface
  (defun chunyang-eww-toggle-image ()
    (interactive)
    (setq shr-inhibit-images (not shr-inhibit-images))
    (eww-reload)
    (message "Image is now %s"
             (if shr-inhibit-images "off" "on")))  
  (defun chunyang-eww-visit-chrome-tab ()
    "EWW URL of the current Chrome Tab."
    (interactive)
    (unless *is-mac*
      (user-error
       "`chunyang-eww-visit-chrome-tab' supports macOS only"))
    (require 'grab-mac-link)
    (require 'dash)
    (-let (((url . _title) (grab-mac-link-chrome-1)))
      (eww url)))
  (defun helm-eww-bookmarks ()
    "Alternative to `eww-list-bookmarks'."
    (interactive)
    (require 'helm)
    (require 'eww)
    (helm :sources
          (helm-build-sync-source "EWW Bookmarks"
            :candidates
            (lambda ()
              (cl-loop for elt in (eww-read-bookmarks)
                       collect (cons (plist-get elt :title)
                                     (plist-get elt :url))))
            :action (helm-make-actions
                     "eww" #'eww
                     "browse-url" #'browse-url
                     "Copy URL" (lambda (url)
                                  (kill-new url)
                                  (message "Copied: %s" url))))
          :buffer "*Helm EWW Bookmarks*"))

  (defun chunyang-eww-import-bookmarks (bookmarks-html-file)
    "Import bookmarks from BOOKMARKS-HTML-FILE.
Note that this will OVERRIDE the existing EWW bookmarks."
    (interactive "fBookmarks HTML File: ")

    ;; Check if some libraries exist
    (require 'eww)
    (unless (require 'dom nil 'no-error)
      (user-error "dom.el not available, it was added in Emacs 25.1"))
    (unless (fboundp 'libxml-parse-html-region)
      (user-error "`libxml-parse-html-region' not available, \
your Emacs doesn't have libxml2 support"))

    (with-temp-buffer
      (insert-file-contents bookmarks-html-file)
      (setq eww-bookmarks
            (loop with dom = (libxml-parse-html-region (point-min) (point-max))
                  for a in (dom-by-tag dom 'a)
                  for url = (dom-attr a 'href)
                  for title = (dom-text a)
                  for time = (current-time-string
                              (seconds-to-time
                               (string-to-number
                                (dom-attr a 'add_date))))
                  collect (list :url url
                                :title title
                                :time time)))
      (eww-write-bookmarks)))

  (defun chunyang-eww-import-bookmarks-from-chrome-1 (json)
    "Adapted from `helm-chrome--add-bookmark'."
    (when (and (listp json) (listp (cdr json)))
      (cond
       ((assq 'roots json)
        (dolist (item (alist-get 'roots json))
          (chunyang-eww-import-bookmarks-from-chrome-1 item)))
       ((equal (alist-get 'type json) "folder")
        (cl-loop for item across (alist-get 'children json)
                 do (chunyang-eww-import-bookmarks-from-chrome-1 item)))
       ((equal (alist-get 'type json) "url")
        (setq eww-bookmarks
              (append eww-bookmarks
                      (list (list
                             :url  (alist-get 'url json)
                             :title (alist-get 'name json)
                             :time (seconds-to-time
                                    (string-to-number
                                     (let ((str (alist-get 'date_added json)))
                                       ;; 1 second = 100,000 micro seconds
                                       (substring str 0 (- (length str) 6)))))))))))))

  (defun chunyang-eww-import-bookmarks-from-chrome ()
    "Import bookmarks from Google Chrome's Bookmarks JSON file.
Note that this will OVERRIDE the existing EWW bookmarks."
    (interactive)
    (chunyang-eww-import-bookmarks-from-chrome-1
     (json-read-file
      "/Users/xcy/Library/Application Support/Google/Chrome/Profile 1/Bookmarks"))
    (eww-write-bookmarks))
  :config
  (bind-key "M" #'chunyang-eww-toggle-image eww-mode-map)
  ;; Sync bookmarks every time from Chrome
  (chunyang-eww-import-bookmarks-from-chrome)
  ;; XXX Both Google & DuckDuckGo are currently bocked in China
  (setq eww-search-prefix "https://duckduckgo.com/html/?q=")
  ;; Eww doesn't support Javascript, but HTTPS version of Google requires it (?)
  ;; (setq eww-search-prefix "https://www.google.com.hk/search?q=")
  (setq eww-search-prefix "http://www.google.com.hk/search?q=")
  (setq eww-search-prefix "https://www.bing.com/search?q="))

(use-package shr-tag-pre-highlight
  :load-path "~/src/shr-tag-pre-highlight.el"
  :ensure t
  :after shr
  :config
  (add-to-list 'shr-external-rendering-functions
               '(pre . shr-tag-pre-highlight))

  (when (version< emacs-version "26")
    (with-eval-after-load 'eww
      (advice-add 'eww-display-html :around
                  'eww-display-html--override-shr-external-rendering-functions))))

(use-package shr
  :defer t
  :config
  ;; Don't use proportional fonts for text
  (setq shr-use-fonts nil))

(use-package shr-color
  :defer t
  :preface
  (defun chunyang-theme-dark-p ()
    "Return t if using Dark theme."
    ;; FIXME: Use a proper way for this
    (let ((theme (car custom-enabled-themes)))
      (and theme
           (or (string-match-p (rx (or "night" "eighties" "dark" "deep"))
                               (symbol-name theme))
               (string= (symbol-name theme) "wombat"))
           t)))
  :config
  (when (chunyang-theme-dark-p)
    ;; (info "(Mu4e) Displaying rich-text messages")
    (setq shr-color-visible-luminance-min 75)))

(use-package google-this
  :disabled t
  :ensure t
  :diminish google-this-mode
  :preface (defvar google-this-keybind (kbd "C-c G"))
  :init (google-this-mode))

(use-package devdocs
  :ensure t
  :commands devdocs-search)

(defun web-search (prefix)
  "Web search with s (see URL `https://github.com/zquestz/s').
Called with a prefix arg set search provider (default Google)."
  (interactive "P")
  (let* ((provider
          (if prefix
              (completing-read
               "Set search provider: "
               (split-string (shell-command-to-string "s -l") "\n" t) nil t)))
         (initial
          (or (if (region-active-p)
                  (buffer-substring-no-properties
                   (region-beginning)
                   (region-end)))
              (thing-at-point 'symbol)
              (thing-at-point 'word)))
         (query (shell-quote-argument (read-string "Web Search: " initial))))
    (call-process-shell-command
     (if provider
         (format "s -p %s %s" provider query)
       (format "s %s" query)) nil)))

(bind-key "M-s M-s" #'web-search)


;;; Music

(use-package emms
  :disabled t
  :ensure t
  :defer t
  :config
  (add-to-list 'Info-directory-list "~/src/emms/doc")

  (setq emms-mode-line-icon-color "purple")

  (require 'emms-setup)
  (emms-all)
  (emms-playing-time -1)
  (setq emms-player-list '(emms-player-mplayer)
        emms-source-file-default-directory "~/Music/网易云音乐"
        emms-source-file-gnu-find "gfind")

  (require 'emms-info-libtag)
  (setq emms-info-functions '(emms-info-libtag))

  (defun chunyang-emms-indicate-seek (_sec)
    (let* ((total-playing-time (emms-track-get
                                (emms-playlist-current-selected-track)
                                'info-playing-time))
           (elapsed/total (/ (* 100 emms-playing-time) total-playing-time)))
      (with-temp-message (format "[%-100s] %2d%%"
                                 (make-string elapsed/total ?=)
                                 elapsed/total)
        (sit-for 2))))

  (add-hook 'emms-player-seeked-functions #'chunyang-emms-indicate-seek 'append))

(use-package bongo
  :disabled t
  :ensure t
  :defer t)


;;; Dictionary
(use-package youdao-dictionary
  :ensure t
  :load-path "~/src/youdao-dictionary.el"
  :bind (("C-c y" . youdao-dictionary-search)
         ("C-c Y" . youdao-dictionary-search-at-point+)))

(use-package osx-dictionary
  :if *is-mac*
  :load-path "~/src/osx-dictionary.el"
  :bind ("C-c d" . osx-dictionary-search-pointer))

(use-package bing-dict
  :ensure t
  :defer t)

(use-package google-translate
  :ensure t
  :defer t
  :preface
  (defvar chunyang-google-translate-history nil)
  (defun chunyang-google-translate (query)
    (interactive
     (let ((default
             (or (and (use-region-p)
                      (buffer-substring
                       (region-beginning) (region-end)))
                 (current-word))))
       (list (read-string (if default
                              (format "Google Translate (default %s): " default)
                            "Google Translate: ")
                          nil
                          'google-translate-history
                          default))))
    (browse-url (format "https://www.google.com/translate_t?text=%s"
                        (url-hexify-string query))))
  :config
  ;; translate.google.com -> translate.google.cn
  ;; Becuase the latter is not blocked in China.
  (dolist (url '(google-translate--tkk-url
                 google-translate-base-url
                 google-translate-listen-url))
    (set url (replace-regexp-in-string
              (regexp-quote "translate.google.com")
              "translate.google.cn"
              (symbol-value url))))

  ;; For M-x `google-translate-smooth-translate'
  (setq google-translate-translation-directions-alist
        '(("en" . "zh-CN") ("zh-CN" . "en"))))

(use-package echo
  :commands echo-mode)




;;; Shell (including shell-command, shell, term and Eshell)

(use-package term
  :commands term
  :config
  ;; Allow more lines before truncating
  (setq term-buffer-maximum-size 10240)

  ;; Respect my own M-x
  (define-key term-raw-escape-map [?\M-x] (lookup-key global-map [?\M-x]))

  ;; C-c C-j   term-line-mode
  ;; C-c C-k   term-char-mode
  ;;
  ;; However, It's hard to remember and distinguish them, so just use C-c C-j to
  ;; toggle these two modes.
  (define-key term-mode-map [?\C-c ?\C-j] 'term-char-mode))

(use-package shell-pop
  :ensure t
  :commands shell-pop)

(use-package pcmpl-git
  :after pcomplete
  :load-path "~/src/pcmpl-git-el")

(use-package eshell-z
  :ensure t
  :commands eshell-z
  :load-path "~/src/eshell-z")

(use-package eshell
  :defer t
  :preface
  (defun chunyang-eshell-insert-last-arg ()
    "Insert the (rough) last arg of the last command, like ESC-. in shell."
    (interactive)
    (with-current-buffer eshell-buffer-name
      (let ((last-arg
             (car (last
                   (split-string
                    (substring-no-properties (eshell-get-history 0)))))))
        (and last-arg (insert last-arg)))))
  :bind ("C-x m" . eshell)              ; 'C-x m' runs `compose-mail' by default
  :config
  (setq eshell-history-size 5000)       ; Same as $HISTSIZE
  (setq eshell-hist-ignoredups t)       ; make the input history more bash-like
  ;; (setq eshell-banner-message
  ;;       '(concat (shell-command-to-string "fortune") "\n"))

  ;; Visual commands like top(1) and vi(1)
  (setq eshell-visual-subcommands '(("git" "log" "diff" "show")))
  (setq eshell-destroy-buffer-when-process-dies t)

  ;; If t, it will make `term' use C-x as escape key, instead of the default C-c
  (setq eshell-escape-control-x nil)

  (add-hook 'eshell-mode-hook
            (defun chunyang-eshell-mode-setup ()
              ;; Setup Plan9 smart shell
              ;; (require 'em-smart)
              ;; (eshell-smart-initialize)
              (bind-keys :map eshell-mode-map
                         ("C-c C-q" . eshell-kill-process)
                         ("M-."     . chunyang-eshell-insert-last-arg))
              (eshell/export "EDITOR=emacsclient -n")
              (eshell/export "VISUAL=emacsclient -n")
              ;; Disable scroll, see
              ;; https://emacs.stackexchange.com/questions/28819/eshell-goes-to-the-bottom-of-the-page-after-executing-a-command
              (remove-hook 'eshell-output-filter-functions
                           'eshell-postoutput-scroll-to-bottom)

              (require 'eshell-z)))


  (use-package eshell-git-prompt
    :load-path "~/src/eshell-git-prompt"
    :ensure t
    :init
    ;; Needed at least for `eshell-git-prompt'?
    ;; (setq eshell-highlight-prompt nil)
    :config
    ;; Type "use-theme" in Eshell to change theme
    ;; (eshell-git-prompt-use-theme 'simple)
    )

  (use-package chunyang-eshell-ext))

(use-package eshell-did-you-mean
  :disabled t
  :load-path "~/src/eshell-did-you-mean"
  :defer t
  :init
  (autoload 'eshell-did-you-mean-setup "eshell-did-you-mean")
  (with-eval-after-load 'eshell
    (eshell-did-you-mean-setup)))


;;; Emacs + Shell

;; 1) Emacs should load `chunyang-shell.el'
;; 2) Shell in external Terminal should load misc/linux.sh or misc/mac.sh

(use-package chunyang-shell)

;; For "emacsclient --eval EXPR". In EXPR, one has to use `setq' to modify this
;; variable temporarily, for example,
;;
;; emacsclient --eval "(progn (setq server-eval-and-how-to-print 'buffer) (org-agenda-list))"
;;
;; `let' will not work.
(defcustom server-eval-and-how-to-print 'supress
  "Custom how to print in `server-eval-and-print'."
  :type '(choice
          (const :tag "Default (that is, print result of evaluation)" nil)
          (const :tag "Supress everything" 'supress)
          (const :tag "Print the current buffer" 'buffer))
  :group 'server)

(define-advice server-eval-and-print (:around (&rest r) how-to-print)
  "Decide how to print in `server-eval-and-print', according to `server-eval-and-how-to-print'."
  (let ((server-eval-and-how-to-print
         server-eval-and-how-to-print))
    (seq-let (_orig-fun expr proc) r
      (let ((v (with-local-quit (eval (car (read-from-string expr))))))
        (pcase server-eval-and-how-to-print
          ('supress
           nil)
          ('buffer
           (when proc
             (require 'e2ansi)
             (server-reply-print
              (server-quote-arg
               (e2ansi-string-to-ansi (buffer-string)))
              proc)))
          (_
           (when proc
             (with-temp-buffer
               (let ((standard-output (current-buffer)))
                 (pp v)
                 (let ((text (buffer-substring-no-properties
                              (point-min) (point-max))))
                   (server-reply-print (server-quote-arg text) proc)))))))))))


;;; Org mode

(use-package calendar
  :init
  ;; 每周从周一开始（需要 load 之前设置）
  (setq calendar-week-start-day 1)
  :defer t)

(use-package org
  :ensure org-plus-contrib
  :init
  ;; Prefer Org mode from git if available
  (add-to-list 'load-path "~/src/org-mode/lisp")
  (add-to-list 'load-path "~/src/org-mode/contrib/lisp")
  ;; Move the directory of `htmlize.el' from Melpa to the beginning of
  ;; `load-path' to make sure it is used, otherwise one older version
  ;; at org git repo will be used.
  (let ((htmlize (cl-find-if
                  (lambda (path)
                    (string-prefix-p "htmlize-" (file-name-nondirectory path)))
                  load-path)))
    (setq load-path (delete htmlize load-path))
    (push htmlize load-path))

  (add-to-list 'Info-directory-list "~/src/org-mode/doc")
  (when *is-mac* (autoload 'org-mac-grab-link "org-mac-link"))
  :defer t
  :bind (("C-c c" . org-capture)
         ("C-c a" . org-agenda)
         ("C-c l" . org-store-link))
  :config

  (setq org-directory          "~/Notes"
        org-default-notes-file (concat org-directory "/notes.org")
        org-agenda-files       (list org-directory))

  ;; Prevent demoting heading also shifting text inside sections
  ;; (setq org-adapt-indentation nil)

  (setq org-src-window-setup 'current-window)

  ;; Support link to Manpage, EWW and Notmuch
  (require 'org-man)
  (require 'org-eww)
  (require 'org-notmuch)

  (use-package ob-lisp                  ; Common Lisp
    :defer t
    :config
    ;; Requires SLY or SLIME, and the latter is used by default
    (setq org-babel-lisp-eval-fn 'sly-eval))

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell      . t)
     (eshell     . t)
     (ruby       . t)
     (python     . t)
     (perl       . t)
     ;; Common Lisp
     (lisp       . t)
     (ditaa      . t)
     ;; Guile, Racket etc
     (scheme     . t)
     ;; C, C++ and D
     (C          . t)
     (latex      . t)
     (R          . t)
     (org        . t)))
  ;; This is not safe
  (setq org-confirm-babel-evaluate nil)

  ;; (org) Easy templates
  (loop for al in '(("E" "#+BEGIN_SRC emacs-lisp\n?\n#+END_SRC"))
        do (add-to-list 'org-structure-template-alist al 'append))

  (defun chunyang-org-info-lookup-symbol ()
    "Call `info-lookup-symbol' within a source edit buffer if needed."
    (interactive)
    (if (not (org-in-src-block-p))
        (call-interactively 'info-lookup-symbol)
      (org-babel-do-in-edit-buffer
       (save-excursion
         (call-interactively 'info-lookup-symbol)))
      (switch-to-buffer-other-window "*info*")))

  (bind-key "C-h S" 'chunyang-org-info-lookup-symbol org-mode-map))

(use-package grab-mac-link
  :if *is-mac*
  :ensure t
  :load-path "~/src/grab-mac-link"
  :commands grab-mac-link
  :init
  (defun chunyang-grab-mac-link-from-chrome-as-org ()
    "Insert link & title of the current tab of Chrome as an Org link."
    (interactive "*")
    (insert (grab-mac-link 'chrome 'org))))

(use-package htmlize                    ; Enable src block syntax
                                        ; highlightting during
                                        ; exporting from org to html
  :ensure t
  :defer t
  ;; :init (setq org-html-htmlize-output-type 'css)
  )

(use-package orglink
  :load-path "~/src/orglink"
  :commands (orglink-mode global-orglink-mode)
  :init (add-hook 'prog-mode-hook #'orglink-mode)
  :config (setq orglink-mode-lighter nil))

;; TODO: Learn more about this package
(use-package org-board                  ; Bookmark with Org
  :ensure t
  :defer t)

(use-package habitica
  :disabled t
  :ensure t
  :defer t)


;;; C

;; C Programming Tools:
;; - GDB (info "(gdb) Top")
;; - GCC (info "(gcc) Top")
;; - CC Mode (info "(ccmode) Top")
;;
;; Note that it's not easy to use GDB on macOS (blame Apple).

(use-package cc-mode
  ;; Tips:
  ;; - C-M-a/e and M-a/e understands functions and statements, it's cool
  :defer t
  :init
  ;; Turn on Auto-newline and hungry-delete-key, they are adviced by cc-mode
  ;; manual, let me try them for a while. BTW, 'a' and 'h' will be indicated in
  ;; the mode-line, such as C/lah.  BTW, 'l' stands for electric keys, use C-c
  ;; C-l to toggle it.
  (add-hook 'c-mode-common-hook 'c-toggle-auto-hungry-state)

  (defun chunyang-c-mode-setup ()
    (when buffer-file-name
      (unless (file-exists-p "Makefile")
        (setq-local compile-command
                    (let ((fn (file-name-nondirectory buffer-file-name)))
                      (format "cc %s -o %s -std=c99 -Wall"
                              (shell-quote-argument fn)
                              (shell-quote-argument (file-name-sans-extension fn)))))))
    (define-key c-mode-map "\C-c\C-c" 'recompile))
  (add-hook 'c-mode-hook 'chunyang-c-mode-setup)

  (defun chunyang-cpp-lookup ()
    "Lookup C function/macro/etc prototype via Preprocessing."
    (interactive)
    (let ((symbol (current-word))
          (buffer "*clang-cpp-output*")
          (file buffer-file-name))
      (with-current-buffer (get-buffer-create buffer)
        (erase-buffer)
        (call-process "cc" nil t nil "-E" file)
        (goto-char (point-min))
        (re-search-forward symbol nil t)
        (display-buffer (current-buffer))))))

(use-package irony
  :disabled t
  :ensure t
  :defer t
  :init
  (add-hook 'c-mode-hook 'irony-mode)

  ;; replace the `completion-at-point' and `complete-symbol' bindings in
  ;; irony-mode's buffers by irony-mode's function
  (defun my-irony-mode-hook ()
    (define-key irony-mode-map [remap completion-at-point]
      'irony-completion-at-point-async)
    (define-key irony-mode-map [remap complete-symbol]
      'irony-completion-at-point-async))
  (add-hook 'irony-mode-hook 'my-irony-mode-hook)
  (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)

  :config
  (use-package company-irony
    :ensure t
    :defer t
    :init (with-eval-after-load 'company
            (add-to-list 'company-backends 'company-irony))
    :config
    ;; Prefer "fun ()" over "fun()"
    (define-advice company-irony--post-completion
        (:override (candidate) put-space-open-parentheses-maybe)
      "Add one space before open-parenthesis if using GNU style."
      (when (and (equal c-indentation-style "gnu")
                 candidate)
        (let ((point-before-post-complete (point)))
          (if (irony-snippet-available-p)
              (irony-completion-post-complete candidate)
            (let ((str (irony-completion-post-comp-str candidate)))
              ;; Prefer GNU C style by adding one space after function
              ;; name (2016-10-24 by xcy)
              (unless (string-empty-p str)
                (insert " "))
              (insert str)
              (company-template-c-like-templatify str)))
          (unless (eq (point) point-before-post-complete)
            (setq this-command 'self-insert-command))))))

  (use-package irony-eldoc        ; Note: this does not work very well
    :ensure t
    :defer t
    :init (add-hook 'irony-mode-hook 'irony-eldoc)))

(use-package flycheck-irony
  :ensure t
  :defer t
  :init
  (eval-after-load 'flycheck
    '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup)))

;; GTK+

(use-package gtk-look
  :if (eq system-type 'gnu/linux)
  :ensure t
  :defer t
  :functions gtk-lookup-cache-init
  :preface
  (defun devhelp (symbol)
    (interactive (list (current-word)))
    (and symbol
         (start-process "devhelp" nil "devhelp" "-s" symbol)))

  (defvar helm-gtk-lookup-symbol-input-history nil)
  (defun helm-gtk-lookup-symbol ()
    (interactive)
    (helm :sources
          (helm-build-sync-source "gtk-doc"
            :candidates (gtk-lookup-cache-init)
            :action
            '(("View gtk-doc in eww" .
               (lambda (entry)
                 (eww-browse-url
                  (concat "file://" (nth 1 entry) (nth 0 entry)))))))
          :input (when (memq major-mode '(c-mode))
                   (current-word))
          :buffer "*helm gtk-doc*"
          :history 'helm-gtk-lookup-symbol-input-history))
  :init
  (defun chunyang-c-mode-setup-gtk ()
    (define-key c-mode-map "\C-h." 'gtk-lookup-symbol))
  (add-hook 'c-mode-hook 'chunyang-c-mode-setup-gtk)
  :config
  ;; Prefer EWW (`browse-url' prefers system's default browser)
  (setq browse-url-browser-function
        '(("file:///usr/share" . eww-browse-url)
          ("." . browse-url-default-browser))))


;;; Common Lisp

(use-package slime
  :disabled t
  :ensure t
  :defer t
  :init (setq inferior-lisp-program "sbcl"))

;; TODO eldoc support (`sly-autodoc-mode') is not working
;; TODO Is completion working? (best with Company support, usually it should work out of box)
(use-package sly
  :ensure t
  :defer t
  :preface
  (defun chunyang-sly-eval-print-last-sexp ()
    "Like `chunyang-eval-print-last-sexp' in Emacs Lisp.
Note that `sly-eval-last-expression' with prefix argument
provides similiar function."
    (interactive)
    (let ((string (sly-last-expression)))
      (sly-eval-async `(slynk:eval-and-grab-output ,string)
        (lambda (result)
          (cl-destructuring-bind (_output value) result
            (unless (chunyang-current-line-empty-p) (insert ?\n))
            ;; (insert "     ⇒ " value)
            (insert "     => " value)
            (unless (chunyang-current-line-empty-p) (insert ?\n)))))))

  (defun chunyang-sly-eval-print-last-sexp-in-comment ()
    (interactive)
    (let ((string (sly-last-expression)))
      (sly-eval-async `(slynk:eval-and-grab-output ,string)
        (lambda (result)
          (cl-destructuring-bind (_output value) result
            (comment-dwim nil)
            (insert (format " => %s" value)))))))
  :config
  (setq inferior-lisp-program "sbcl")
  (define-key sly-mode-map "\C-j" #'chunyang-sly-eval-print-last-sexp)
  (define-key sly-mode-map "\C-j" #'chunyang-sly-eval-print-last-sexp-in-comment))

(use-package sly-mrepl
  :no-require t                      ; Silence byte-compiling warnning
  :defer t
  :config
  ;; Enable Paredit in REPL too
  (add-hook 'sly-mrepl-mode-hook #'paredit-mode))

;;; Ruby

(use-package ruby-mode
  :defer t
  :init
  (add-hook 'ruby-mode-hook 'superword-mode))

(use-package inf-ruby
  :ensure t
  ;; `package.el' does the setup via autoload
  :defer t)

(use-package robe
  ;; NOTE: Some gems have to be installed before using, see
  ;;       https://github.com/dgutov/robe
  :ensure t
  :after ruby-mode
  :config
  (add-hook 'ruby-mode-hook 'robe-mode))

(use-package ruby-tools
  :disabled t
  :ensure t
  :defer t
  :init (add-hook 'ruby-mode-hook 'ruby-tools-mode))


;; For the Programming Languages course
(use-package sml-mode
  :ensure t
  :defer t)

(use-package sml-eldoc
  :commands sml-eldoc-turn-on
  :init (add-hook 'sml-mode-hook 'sml-eldoc-turn-on))

(use-package ob-sml
  :ensure t
  :defer t
  :init (with-eval-after-load 'org
          (require 'ob-sml)))

(use-package skalpel
  :disabled t
  :load-path "~/skalpel/front-ends/emacs/"
  :init
  (defvar skalpel-emacs-directory "~/skalpel/front-ends/emacs/")
  (defvar skalpel-bin-directory "~/skalpel/analysis-engines/standard-ml/bin/")
  (defvar skalpel-lib-directory "~/skalpel/lib/")
  (defvar skalpel-sources-directory "~/skalpel/analysis-engines/standard-ml/")
  (with-eval-after-load 'sml-mode
    (load "skalpel-config.el")))

;; [Don't copy-paste on the Extra Practice Problems page](https://www.coursera.org/learn/programming-languages/discussions/weeks/2/threads/_k7m9FTgEeaslgpY-vgBqw
(defun convert-MathJax-Unicode-to-ASCII (beg end)
  "Convert [0-9a-zA-Z] in Unicode to their ASCII in the region."
  (interactive "r")
  (insert (mapconcat (lambda (c)
                       (char-to-string
                        (cond
                         ((<= ?𝟶 c ?𝟿) (+ ?0 (- c ?𝟶)))
                         ((<= ?𝚊 c ?𝚣) (+ ?a (- c ?𝚊)))
                         ((<= ?𝙰 c ?𝚉) (+ ?A (- c ?𝙰)))
                         (t c))))
                     (delete-and-extract-region beg end) "")))
;; Testing
;;
;; Before:
;; EXAMPLE: 𝚞𝚗𝚏𝚘𝚕𝚍 (𝚏𝚗 𝚡 => 𝚒𝚏 𝚡 > 𝟹 𝚝𝚑𝚎𝚗 𝙽𝙾𝙽𝙴 𝚎𝚕𝚜𝚎 𝚂𝙾𝙼𝙴 (𝚡 + 𝟷, 𝚡)) 𝟶 = [𝟶, 𝟷, 𝟸, 𝟹]
;; After:
;; EXAMPLE: unfold (fn x => if x > 3 then NONE else SOME (x + 1, x)) 0 = [0, 1, 2, 3]

(use-package geiser                     ; For Scheme
  :ensure t
  :defer t
  :defines geiser-mode-map
  :preface
  ;; Important keys:
  ;; C-c C-z - Switch between source and REPL
  ;; C-z C-a - Switch to REPL with current module
  (defun chunyang-geiser-setup ()
    (bind-keys :map geiser-mode-map
               ("C-h ."   . geiser-doc-symbol-at-point)
               ("C-h C-." . geiser-doc-look-up-manual)))
  :config
  (setq geiser-default-implementation 'guile)
  ;; See (info "(geiser) Must needs") for URLs to them
  (setq geiser-active-implementations '(guile racket chicken chez))

  (add-hook 'geiser-mode-hook #'chunyang-geiser-setup)

  ;; Yes, use ParEdit in the REPL too
  (add-hook 'geiser-repl-mode-hook #'paredit-mode))

(add-hook 'scheme-mode-hook #'paredit-mode)

(use-package racket-mode
  :disabled t
  :ensure t
  :defer t
  :init
  ;; Doing this is because geiser sets *.rkt as scheme mode and overrides
  ;; racket-mode
  (push '("\\.rkt[dl]?\\'" . racket-mode) auto-mode-alist))


;;; Web

(use-package css-mode
  :defer t
  :config (setq css-indent-offset 2))

;; TODO Try this package (examples, documentation)
(use-package web-server
  :ensure t
  :defer t)


;;; Python

(use-package python
  :disabled t
  :defer t
  :init
  (setq python-shell-interpreter "python3"
        python-shell-completion-native-enable nil))


;; OCaml
(use-package OCaml
  :disabled t
  :ensure tuareg
  :preface
  ;; 官方的 Manual （竟然）提供了 Info 格式 <http://caml.inria.fr/pub/docs/manual-ocaml/>
  (add-to-list 'Info-directory-list "~/Documents/ocaml-4.03-info-manual")
  :defer t)


;; shen <http://shenlanguage.org/>
(use-package shen-mode
  :ensure t
  :defer t)

(use-package shen-elisp
  :ensure t
  :defer t)


;; AppleScript
(use-package applescript-mode
  ;; Needs build with ns (cocoa) support
  :if (and (eq 'darwin system-type) (eq 'ns window-system))
  :ensure t
  :mode ("\\.applescript\\'" "\\.scpt\\'"))


;;; Math

(use-package Maxima
  :disabled t
  :load-path "/usr/local/Cellar/maxima/5.37.2/share/maxima/5.37.2/emacs"
  :mode ("\\.ma[cx]" . maxima-mode)
  :init
  (autoload 'maxima-mode "maxima"  "Maxima mode"                            t)
  (autoload 'imaxima     "imaxima" "Frontend for maxima with Image support" t)
  (autoload 'maxima      "maxima"  "Maxima interaction"                     t)
  (autoload 'imath-mode  "imath"   "Imath mode for math formula input"      t)
  (setq imaxima-use-maxima-mode-flag t))


;;; Misc

;; Socks5 proxy setting for `url.el'
(setq socks-server '("Default server" "127.0.0.1" 1080 5))

;; 白名单
(setq url-gateway-local-host-regexp
      (concat "\\`"
              (regexp-opt '("localhost"
                            "127.0.0.1"
                            "elpa.emacs-china.org"))
              "\\'"))

;; (setq url-gateway-method 'socks)

;; XXX 好像不会及时生效 (?)
;; (define-minor-mode chunyang-socks-proxy-mode
;;   "Toggle Socks Proxy mode for the 'url' library."
;;   :global t
;;   (setq url-gateway-method
;;         (if chunyang-socks-proxy-mode
;;             'socks
;;           'native)))

(use-package url-cookie
  :defer t
  :init
  ;; Disable saving cookie to disk because periodically message like
  ;; the following
  ;;
  ;; Saving file /Users/xcy/.emacs.d/var/url/configuration/cookies...
  ;; Wrote /Users/xcy/.emacs.d/var/url/configuration/cookies
  ;;
  ;; is very annoying.
  (setq url-cookie-save-interval nil))

(use-package ascii-art-to-unicode
  :ensure t
  :defer t
  :init
  ;; `aa2u' is hard to recall
  (defalias 'ascii-art-to-unicode 'aa2u))

(use-package time-stamp                 ; Built-in
  :defer t
  :init (add-hook 'before-save-hook 'time-stamp))

(use-package autoinsert
  ;; :emacwiki "https://www.emacswiki.org/emacs/AutoInsertMode"
  :defer t
  :config
  ;; Note that the following should not be evaled more than once
  (define-auto-insert
    '(sh-mode . "Shell Script header")
    ;; (info "(autotype) Skeleton Language")
    '("Short description: "
      "#!/bin/sh" \n
      "# " (file-name-nondirectory (buffer-file-name)) " - " str \n
      \n \n)))

(use-package restart-emacs :ensure t :defer t)

(use-package package-utils :ensure t :defer t)

;; See [[https://xuchunyang.me/Logs/upgrade-packages-then-restart-emacs.html][升级 Emacs Package 然后重启 Emacs]]
(defun chunyang-upgrade-packages-then-restart-emacs ()
  (interactive)
  (package-utils-upgrade-all)
  (restart-emacs))

(use-package e2ansi                     ; Provide Syntax Highlight for shell by
                                        ; Emacs.  This is very cool.
  :ensure t
  :load-path "~/src/e2ansi"
  :defer t)


;;; Game

(use-package threes
  :ensure t
  :defer t)

(use-package chunyang-fun               ; For fun
  :init
  (let ((org (locate-user-emacs-file "lisp/chunyang-fun.org"))
        (el  (locate-user-emacs-file "lisp/chunyang-fun.el")))
    (when (file-newer-than-file-p org el)
      (org-babel-tangle-file org)
      (byte-compile-file el)))
  :commands chunyang-fun-roll-news)

(use-package chunyang-picture
  :commands (chunyang-download-bing-picture
             chunyang-about-honey-select)
  ;; :bind ("C-h C-a" . chunyang-about-honey-select)
  :bind (:map splash-screen-keymap ("g" . chunyanb-about-emacs-refresh))
  :config
  ;; (add-hook 'emacs-startup-hook
  ;;           (lambda ()
  ;;             (toggle-frame-maximized)
  ;;             (sit-for 1)
  ;;             (about-emacs)))
  ;; (setq fancy-splash-image
  ;;       (chunyang-download-bing-picture "~/Pictures" "bing.jpg"))
  )

(use-package fortune
  :commands (fortune fortune-message)
  :config
  (cond (*is-mac*
         ;; On macOS, fortune is installed via MacPorts
         (setq fortune-dir  "/opt/local/share/games/fortune/"
               fortune-file "/opt/local/share/games/fortune/fortunes"))
        (*is-gnu-linux*
         (setq fortune-dir  "/usr/share/games/fortunes/"
               fortune-file "/usr/share/games/fortunes/fortunes"))))


;;; IM

(use-package gitter
  :load-path "~/src/gitter.el"
  :ensure t
  :defer t
  :commands gitter
  :init
  (setq gitter--debug t))


;;; Programming Language

(use-package language-detection
  :ensure t
  :defer t
  :preface
  (defun chunyang-language-detection-region (b e)
    (interactive "r")
    (message "Language: %s"
             (language-detection-string (buffer-substring b e)))))


;;; Emacs

;; FIXME: In case Emacs can't find the source (for example, installing Emacs via
;;        MacPorts). Remove it someday
(setq source-directory "~/src/emacs/")


;;; Chinese | 中文
(use-package chunyang-chinese
  :commands (chunyang-chinese-insert-mark
             chinese-punctuation-mode)
  :demand
  :config (chinese-punctuation-mode))

;; macOS 下，使用官方 GUI Emacs 和系统自带的拼音输入法时，输入期间，在
;; Emacs buffer 已出现字母会随着输入的进行而发生“抖动”，相关讨论：
;; - https://emacs-china.org/t/mac-gui-emacs/186
;; - https://debbugs.gnu.org/cgi/bugreport.cgi?bug=+23412

;; 临时解决方法，有效但不清楚有没有副作用
;; (setq redisplay-dont-pause nil)


;;; PDF

(use-package pdf-tools
  :if *is-gnu-linux*
  :ensure t
  ;; XXX defer loading this
  :init (pdf-tools-install))


;;; Fun

(use-package sl
  :ensure t
  :load-path "~/src/sl.el"
  :commands (sl sl-little sl-forever sl-little-forever sl-screen-saver))

(use-package xpm
  :homepage "http://www.gnuvola.org/software/xpm/"
  :ensure t
  :defer t)

(use-package gnugo                      ; 围棋
  :ensure t
  :disabled t)

(use-package chess                      ; 国际象棋
  :ensure t
  :disabled t)

(use-package spinner
  :summary "Add spinners and progress-bars to the mode-line for ongoing operations"
  :ensure t
  :defer t)



;;; init.el ends here
