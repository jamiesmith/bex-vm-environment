(setq mouse-yank-at-point t)

(setq initial-frame-alist '(
		(top . 15 ) 
		(left . 60)
		(width . 132) 
		(height . 50)
	)
)

;; Dont show the GNU splash screen
(setq inhibit-startup-message t)
 
(setq x-select-enable-clipboard t)
(setq mouse-sel-default-bindings 'interprogram-cut-paste)
(setq completion-ignored-extensions
  (delete ".log" completion-ignored-extensions))
(setq completion-ignored-extensions
  (delete "CVS" completion-ignored-extensions))
(setq completion-ignored-extensions
  (delete ".fmt" completion-ignored-extensions))

(setq display-warning-minimum-level 'error)
(define-key global-map "\M-p" 'call-last-kbd-macro)
(define-key global-map "\C-x?" 'help-for-help)
(global-unset-key "\C-x\C-g")
(define-key global-map "\C-x\C-g" 'goto-line)
(define-key global-map "\C-x\C-r" 'revert-buffer)
(define-key global-map "\C-c\C-r" 'unconfirmed-revert-buffer)
(define-key global-map "\C-xg" 'goto-line)
(define-key global-map "\M-g" 'goto-line)
(define-key global-map "\C-r" 'replace-string)
(define-key global-map "\C-x." 'set-mark-command)
 
(global-unset-key "\C-u")
(global-unset-key "\M-\C-H")
(define-key global-map "\C-H" 'backward-delete-char-untabify)
(define-key global-map "\M-\C-d" 'backward-kill-word)
(define-key global-map "\M-\C-H" 'backward-kill-word)
(define-key global-map "\C-X\C-Q" 'query-replace)
(define-key global-map "\M-&" 'replace-regexp)
(define-key global-map "\C-u" 'undo)
(define-key global-map "\C-x\C-l" 'what-line)
;; (define-key global-map "\C-x\C-b" 'switch-to-buffer)
(define-key global-map "\C-xt" 'transpose-orientation)
(define-key global-map "\C-xx" 'copy-region-as-kill)
(define-key global-map "\M-n" 'next-file)

;; Text formatting
(global-set-key "\C-xp" 'fill-individual-paragraphs)

(setq-default fill-column 80)

(setq column-number-mode t)

(line-number-mode t)
(column-number-mode t)
 
(fset 'yes-or-no-p 'y-or-n-p) 

(setq nxml-child-indent 8)
(setq nxml-attribute-indent 8)

(setq sgml-basic-offset 8)
 
(setq truncate-partial-width-windows nil)
(setq c-indent-level 8)
(setq c-brace-offset -8)
(setq c-auto-newline 1)
(setq menu-bar-mode 1)
(setq vc-handle-cvs nil)
(setq vc-follow-symlinks t)
(setq auto-mode-alist (cons '("\.cat$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.sdl$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.soc$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.kds$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.php$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.osc$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.act$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.kpm$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.kcs$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.fmt$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.fs$" . c++-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\.rulefunction$" . java-mode) auto-mode-alist))


(setq comment-padding " JRS ")

(add-hook 'xml-mode-hook 
  (function (lambda ()
              (setq comment-padding "  "))))

(setq sgml-mode-hook xml-mode-hook )

(add-to-list 'load-path (expand-file-name "~/emacs/site-lisp"))
(add-to-list 'load-path (expand-file-name "~/utils"))
(add-to-list 'load-path (expand-file-name "~/emacs/share/emacs/21.2/lisp"))

(autoload 'ruby-mode "ruby-mode" "Mode for ruby" t)

(setq auto-mode-alist (cons '("\\.php3\\'" . php-mode) auto-mode-alist))
;;(setq auto-mode-alist (cons '("\\.php\\'" . php-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.phtml\\'" . php-mode) auto-mode-alist))
;;(setq auto-mode-alist (cons '("\\.inc\\'" . php-mode) auto-mode-alist))


(setq auto-mode-alist (cons '("\\.ksh\\'" . shell-script-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.plugin\\'" . shell-script-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.env\\'" . shell-script-mode) auto-mode-alist))

(defun unconfirmed-revert-buffer ()
  "Revert current buffer.  Confirm only if modified."
  (interactive)
  (if (buffer-modified-p)
      (revert-buffer)
    (revert-buffer nil t)
    (message "Buffer Reverted")
)) 

(defun jrs-sw-sccs-get-file()
  (interactive)
  (let ((filename (buffer-file-name)))
    (if (null filename)
        (error "Buffer has no filename")
      (shell-command (concat "chmod +w " (file-name-nondirectory (buffer-file-name))))
      (unconfirmed-revert-buffer))))
  
(defun jrs-insert-buffer-filename ()
  (interactive)
  (let ((filename (buffer-file-name)))
    (if (null filename)
        (error "Buffer has no filename")
      (insert (file-name-nondirectory filename)))))

;; Action Language helper macros
;;
(defun jrs-insert-review-comment()
  (interactive)
  (end-of-line) 
  (insert (format "                                        "))
  (insert (format "                                        x"))
  (beginning-of-line)
  (forward-char 85)
  (kill-line)
  (insert (format "// JRS COMMENT: "))
  )


(defun jrs-insert-fix-this()
  (interactive)
;;    (insert (format "// FIX THIS: JRS ") (format-time-string "%B %d, %Y") (format ", ESP:") ))
    (insert (format "// FIX THIS: JRS ") (format-time-string "%B %d, %Y")))

(defun insert-line-number()
  (interactive)
    (insert (what-line)))

(defun transpose-orientation()
  (interactive)
  (delete-other-windows)
  (split-window-horizontally)
;;  (other-window 1)                                                                                                                                                    
  (switch-to-buffer (other-buffer))
)

(defun jrs-insert-action-language-trace ()
  (interactive)
  (let ((my-buffer-name (buffer-name nil))
	(my-line-number (count-lines-region (point-min) (point))))
    (insert (format "SW_TRC_MSG0(SWTrace::User, SWTrace::Info, \"\");"
		        my-buffer-name my-line-number))))

(defun jrs-insert-action-language-expose() "action lang expose" 
  (interactive) 
  (end-of-line) 
  (fixup-whitespace) 
  (backward-delete-char 4) 
  (backward-kill-word 1) 
  (insert (format "\texpose entity ")) 
  (yank) 
  (insert (format "Impl with\n\t\tinterface ")) 
  (yank) 
  (insert (format ";\n")) 
  ) 


(defun jrs-insert-action-language-header() "action lang header" 
  (interactive) 
  (beginning-of-line) 
  (forward-word 3) 
  (backward-word 1) 
  (kill-word 1) 
  (yank) 
  (beginning-of-line) 
  (previous-line 1)
  (insert (format "// *****************************************************************************\n")) 
  (insert (format "// ")) 
  (yank) 
  (insert (format "\n")) 
  (insert (format "// *****************************************************************************\n")) 
  (insert (format "\n")) 
  )

(defun jrs-insert-file-header() "File Header " 
  (interactive) 
  (insert (format "// Name\n"))
  (insert 
   (format "//\t")
   (file-name-nondirectory buffer-file-name)
   (format "\n")
   )
  (insert (format "//\n"))
  (insert (format "// Copyright\n"))
  (insert (format "//\tConfidential Property of TIBCO Software, Inc.\n"))
  (insert 
   (format "//\tCopyright ") 
   (format-time-string "%Y")
   (format " by TIBCO Software, Inc.\n")
  )
  (insert (format "//\tAll rights reserved.\n"))
  (insert (format "//\n"))
  (insert (format "// History\n")) 
  (insert (format "//\t$Author::                                               $\n"))
  (insert (format "//\t$Date::                                                 $\n"))
  (insert (format "//\t$Revision::                                             $\n"))
  (insert (format "//\n"))
  (insert (format "\n"))
)

(global-set-key (kbd "C-c a") 'jrs-insert-action-language-header)
(global-set-key (kbd "C-c h") 'jrs-insert-file-header)
(global-set-key (kbd "C-c d") 'jrs-insert-action-language-trace)
(global-set-key (kbd "C-c f") 'jrs-insert-fix-this)
(global-set-key (kbd "C-x c") 'jrs-insert-review-comment)
(global-set-key (kbd "C-c c") 'comment-region)
(global-set-key (kbd "C-c u") 'uncomment-region)
(global-set-key (kbd "C-c e") 'jrs-insert-action-language-expose)
(global-set-key (kbd "C-c n") 'jrs-insert-buffer-filename)
(global-set-key (kbd "C-c g") 'jrs-sw-sccs-get-file)
(global-set-key (kbd "C-c t") 'jrs-insert-action-language-trace)

(define-key global-map "\M-\C-H" 'backward-kill-word)
(define-key global-map "\C-x\C-j" 'fixup-whitespace)
 
;some source code editing helpers
;(load "cc-mode")
(require 'cc-mode)

(eval-when-compile
 (require 'cl))

(defun insert-line-numbers (beg end &optional start-line)
  "Insert line numbers into buffer."
  (interactive "r")
  (save-excursion
    (let ((max (count-lines beg end))
          (line (or start-line 1))
          (counter 1))
      (goto-char beg)
      (while (<= counter max)
        (insert (format "%0d " line))
        (beginning-of-line 2)
        (incf line)
        (incf counter)))))


(setq-default c-basic-offset 8 tab-width 8 indent-tabs-mode t)
 
(defconst my-c-style
  '((c-tab-always-indent           . t)
    (c-comment-only-line-offset    . 0)
    (c-hanging-braces-alist        . ((substatement-open after)
                                      (brace-list-open)))
    (c-hanging-colons-alist        . ((member-init-intro before)
                                      (inher-intro)
                                      (case-label after)
                                      (label after)
                                      (access-label after)))
    (c-cleanup-list                . (scope-operator
                                      empty-defun-braces
                                      defun-close-semi))
    (c-offsets-alist               . ((arglist-close     . c-lineup-arglist)
                                      (substatement-open . 0)
                                      (case-label        . 8)
                                      (block-open        . 0)
                                      (statement-block-intro . 8)
                                      (defun-block-intro . 8)))
    (c-echo-syntactic-information-p . t)
    )
  "My C Programming Style")
 
(defvar c-hanging-braces-alist '())
(defun my-c-mode-common-hook ()
  ;; add my personal style and set it for the current buffer
  (c-add-style "PERSONAL" my-c-style t)
  ;; offset customizations not in my-c-style
;;  (c-set-offset 'member-init-intro '++)
  ;; other customizations
  (c-toggle-auto-hungry-state 0)
  ;; Keybindings for all supported languages.  We can put these in
  ;; c-mode-map because c++-mode-map, objc-mode-map, and java-mode-map
  ;; inherit from it.
  (define-key c-mode-map "\C-m" 'newline-and-indent)
  )
 
;; the following only works in Emacs 19
;; Emacs 18ers can use (setq c-mode-common-hook 'my-c-mode-common-hook)
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)
 
;; Options Menu Settings
;; =====================
(cond
 ((and (string-match "XEmacs" emacs-version)
       (boundp 'emacs-major-version)
       (or (and
            (= emacs-major-version 19)
            (>= emacs-minor-version 14))
           (= emacs-major-version 20))
       (fboundp 'load-options-file))
  (load-options-file "$HOME/.xemacs-options")))
;; ============================
;; End of Options Menu Settings

(custom-set-variables
  ;; custom-set-variables was added by Custom -- don't edit or cut/paste it!
  ;; Your init file should contain only one such instance.
 '(case-fold-search t)
 '(current-language-environment "ASCII")
 '(global-font-lock-mode t nil (font-lock))
 '(query-user-mail-address nil)
 '(transient-mark-mode t))
(custom-set-faces
  ;; custom-set-faces was added by Custom -- don't edit or cut/paste it!
  ;; Your init file should contain only one such instance.
 '(custom-comment-face ((((class grayscale color) (background light)) (:background "gray85" :foreground "black")))))

(defalias 'list-buffers 'ibuffer)

(global-set-key [(meta backspace)] 'backward-kill-word)
(define-key c-mode-map "\e\C-h" 'backward-kill-word)
(define-key c++-mode-map "\e\C-h" 'backward-kill-word)

;;
;; Change how we do backups
;;
(setq backup-directory-alist `(("." . "~/.autosaves")))
(setq backup-by-copying t)

(setq delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)
