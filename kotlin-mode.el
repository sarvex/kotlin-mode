;;; kotlin-mode.el --- Major mode to edit Kotlin files in Emacs

;; Copyright (C) 2014 Ayato Nishimura

;; Version: 20140602.001
;; X-Original-Version: 0.0.1
;; Keywords: Kotlin major mode
;; Author: Ayato Nishimura
;; URL: http://kotlin.jetbrains.org/
;; Package-Requires: ((emacs "24.3"))

;;; Commentary
;; support in near future
;; - indetation
;; - imenu
;; - menu bar
;; - command

;;; Code:

(require 'comint)
(require 'easymenu)
(require 'font-lock)
(require 'rx)

(require 'cl-lib)

;;
;; Customizable Variables
;;

(defconst kotlin-mode-version "0.0.1"
  "The version of `kotlin-mode'.")

(defgroup kotlin nil
  "A Kotlin major mode."
  :group 'languages)

(defcustom kotlin-tab-width tab-width
  "The tab width to use when indenting."
  :type 'integer
  :group 'kotlin
  :safe 'integerp)

(defcustom kotlin-command "kotlinc"
  "The Kotlin command used for evaluating code."
  :type 'string
  :group 'kotlin)

(defcustom kotlin-args-repl '()
  "The arguments to pass to `kotlin-command' to start a REPL."
  :type 'list
  :group 'kotlin)

(defcustom kotlin-repl-buffer "*KotlinREPL*"
  "The name of the KotlinREPL buffer."
  :type 'string
  :group 'kotlin)

(defcustom kotlin-mode-hook nil
  "Hook called by `kotlin-mode'.  Examples:"
  :type 'hook
  :group 'kotlin)

(defvar kotlin-mode-map
  (let ((map (make-sparse-keymap)))
    ;; key bindings
    (define-key map (kbd "C-c C-z") 'kotlin-repl)
    (define-key map [remap comment-dwim] 'kotlin-comment-dwim)
    ;; (define-key map [remap newline-and-indent] 'kotlin-newline-and-indent)
    ;; (define-key map (kbd "C-c C-l") 'kotlin-send-line)
    ;; (define-key map (kbd "C-c C-r") 'kotlin-send-region)
    ;; (define-key map (kbd "C-c C-b") 'kotlin-send-buffer)
    (define-key map (kbd "<backtab>") 'kotlin-indent-shift-left)
    (define-key map (kbd "C-M-a") 'kotlin-beginning-of-defun)
    (define-key map (kbd "C-M-e") 'kotlin-end-of-block)
    ;; (define-key map (kbd "C-M-h") 'kotlin-mark-defun)
    map)
  "Keymap for Kotlin major mode.")

;;
;; Commands
;;
(defun kotlin-repl ()
  "Launch a Kotlin REPL using `kotlin-command' as an inferior mode."
  (interactive)

  (unless (comint-check-proc kotlin-repl-buffer)
    (set-buffer
     (apply 'make-comint "KotlinREPL"
            "env"
            nil
            "NODE_NO_READLINE=1"
            kotlin-command
            kotlin-args-repl))

    (set (make-local-variable 'comint-preoutput-filter-functions)
         (cons (lambda (string)
                 (replace-regexp-in-string "\x1b\\[.[GJK]" "" string)) nil)))

  (pop-to-buffer kotlin-repl-buffer))

(defun kotlin-version ()
  "Show the `kotlin-mode' version in the echo area."
  (interactive)
  (message (concat "kotlin-mode version " kotlin-mode-version)))

;; Class
(defvar kotlin-class-regexp "<?:?[A-Z]+[a-z]+\>\?")

;; Constants variables
(defvar kotlin-constants-regexp "[A-Z\_]+")

;; Local Assignment
(defvar kotlin-local-assign-regexp "\\(var\\|val\\)\\s-*\\([[:word:].$]+\\)\\s-*")

;; Number
(defvar kotlin-number-regexp "\\<\\(0[0-7]*\\|0[xX][0-9]+\\|[0-9]+\\)\\>")
(defvar kotlin-float-number-regexp "\\(\\<[0-9]+\\.[0-9]*\\|\\.[0-9]+\\)\\([eE][-+]\?[0-9]+\\)\?[fFdD]\?")

;; String Interpolation(This regexp is taken from kotlin-mode)
(defvar kotlin-string-interpolation-regexp "\\$\\({[^}\n\\\\]*\\(?:\\\\.[^}\n\\\\]*\\)*}\\|\\w+\\)")

;; Kotlin Keywords
(defvar kotlin-keywords
  '("namespace" "import" "package" "fun" "if" "then" "else" "while" "for" "do"
    "type" "val" "var" "return" "true" "false" "null" "this" "super"
    "abstract" "final" "enum" "open" "attribute"
    "public" "private" "protected" "abstract"
    "final" "open" "override" "throw" "try" "catch" "finally"
    "class" "trait" "object"))

;; Regular expression combining the above three lists.
(defvar kotlin-keywords-regexp
  ;; keywords can be member names.
  (concat "\\(?:^\\|[^.]\\)"
          (regexp-opt (append kotlin-keywords) 'symbols)))

;; Create the list for font-lock. Each class of keyword is given a
;; particular face.
(defvar kotlin-font-lock-keywords
  `(
    (,kotlin-class-regexp . font-lock-type-face)
    (,kotlin-constants-regexp . font-lock-constant-face)
    (,kotlin-keywords-regexp 1 font-lock-keyword-face)
    (,kotlin-float-number-regexp . font-lock-constant-face)
    (,kotlin-number-regexp 1 font-lock-constant-face)
    (,kotlin-local-assign-regexp 2 font-lock-variable-name-face)
    (,kotlin-string-interpolation-regexp 0 font-lock-variable-name-face t)
    ))

;;
;; Helper Functions
;;
(defun kotlin-comment-dwim (arg)
  "Comment or uncomment current line or region in a smart way.
For details, see `comment-dwim'."
  (interactive "*P")
  (require 'newcomment)
  (let ((deactivate-mark nil) (comment-start "//") (comment-end ""))
    (comment-dwim arg)))

;;
;; Define Major Mode
;;
(define-derived-mode kotlin-mode prog-mode "Kotlin"
  "Major mode for editing Kotlin."

  ;; code for syntax highlighting
  (setq font-lock-defaults '((kotlin-font-lock-keywords)))

  ;; C style comment: "// ..."
  (modify-syntax-entry ?\/ ". 12b" kotlin-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" kotlin-mode-syntax-table)

  (set (make-local-variable 'comment-start) "//")
  )

(provide 'kotlin-mode)

;;
;; On Load
;;
;; Run Kotlin for files ending in .kt.
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.kt\\'" . kotlin-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.jet\\'" . kotlin-mode))

;;; kotlin-mode.el ends here
