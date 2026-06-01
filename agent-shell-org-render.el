;;; agent-shell-org-render.el --- Org-style overlay rendering for agent-shell viewport  -*- lexical-binding: t -*-

;; Copyright (C) 2025
;; Author: Hyeonjun Park
;; URL: https://github.com/YOUR-USERNAME/agent-shell-org-render
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: convenience, tools

;; This package is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This package is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this package.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-style overlay rendering for agent-shell viewport buffers.
;; Converts markdown syntax to org-style visual representation using
;; display property overlays without modifying buffer text.

;;; Code:

(require 'cl-lib)
(require 'map)
(require 'org-faces)

(eval-when-compile
  (require 'subr-x))

;; ─────────────────────────────────────────────
;; Custom Variables
;; ─────────────────────────────────────────────

(defgroup agent-shell-org-render nil
  "Org-style overlay rendering for agent-shell viewport."
  :group 'convenience)

(defcustom agent-shell-org-render-enable-images t
  "Whether to render LaTeX, Mermaid, Ditaa blocks as images."
  :type 'boolean
  :group 'agent-shell-org-render)

(defcustom agent-shell-org-render-mermaid-backend 'api
  "Mermaid rendering backend.
'cli  - Use mmdc (mermaid-cli) locally
'api  - Use mermaid.ink API
nil   - Disable mermaid rendering"
  :type '(choice (const :tag "CLI (mmdc)" cli)
                 (const :tag "API (mermaid.ink)" api)
                 (const :tag "Disabled" nil))
  :group 'agent-shell-org-render)

(defcustom agent-shell-org-render-latex-process 'dvipng
  "LaTeX rendering process.
'dvipng   - Use dvipng (faster, lower quality)
'dvisvgm  - Use dvisvgm (slower, vector quality)
nil       - Disable LaTeX rendering"
  :type '(choice (const :tag "dvipng" dvipng)
                 (const :tag "dvisvgm" dvisvgm)
                 (const :tag "Disabled" nil))
  :group 'agent-shell-org-render)

(defcustom agent-shell-org-render-auto-apply-in-viewport t
  "Auto-apply org rendering when viewport opens."
  :type 'boolean
  :group 'agent-shell-org-render)

;; ─────────────────────────────────────────────
;; Core Overlay Engine
;; ─────────────────────────────────────────────

(defvar agent-shell-org-render--overlay-category 'agent-shell-org-render
  "Overlay category for org-render overlays.")

(defun agent-shell-org-render-put ()
  "Apply org-style overlays to current buffer.
Returns an alist with details of all overlays added."
  (agent-shell-org-render-remove)
  ;; Remove competing markdown overlays (shell-maker)
  (remove-overlays (point-min) (point-max) 'category 'markdown-overlays)
  (let* ((source-blocks (agent-shell-org-render--source-blocks))
         (source-block-ranges (seq-map (lambda (block)
                                         (cons (car (map-elt block 'start))
                                               (cdr (map-elt block 'end))))
                                       source-blocks))
         (inline-codes (agent-shell-org-render--inline-codes source-block-ranges))
         (inline-code-ranges (seq-map (lambda (ic) (map-elt ic 'body)) inline-codes))
         (avoid-ranges (append inline-code-ranges source-block-ranges))
         (headers (agent-shell-org-render--headers avoid-ranges))
         (bolds (agent-shell-org-render--bolds avoid-ranges))
         (italics (agent-shell-org-render--italics avoid-ranges))
         (links (agent-shell-org-render--links avoid-ranges))
         (strikethroughs (agent-shell-org-render--strikethroughs avoid-ranges)))
    (dolist (header headers)
      (agent-shell-org-render--fontify-header
       (map-elt header 'start)
       (map-elt header 'end)
       (car (map-elt header 'level))
       (cdr (map-elt header 'level))
       (car (map-elt header 'title))
       (cdr (map-elt header 'title))))
    (dolist (bold bolds)
      (agent-shell-org-render--fontify-bold
       (map-elt bold 'start)
       (map-elt bold 'end)
       (car (map-elt bold 'text))
       (cdr (map-elt bold 'text))))
    (dolist (italic italics)
      (agent-shell-org-render--fontify-italic
       (map-elt italic 'start)
       (map-elt italic 'end)
       (car (map-elt italic 'text))
       (cdr (map-elt italic 'text))))
    (dolist (link links)
      (agent-shell-org-render--fontify-link
       (map-elt link 'start)
       (map-elt link 'end)
       (car (map-elt link 'title))
       (cdr (map-elt link 'title))
       (car (map-elt link 'url))
       (cdr (map-elt link 'url))))
    (dolist (strikethrough strikethroughs)
      (agent-shell-org-render--fontify-strikethrough
       (map-elt strikethrough 'start)
       (map-elt strikethrough 'end)
       (car (map-elt strikethrough 'text))
       (cdr (map-elt strikethrough 'text))))
    (dolist (inline-code inline-codes)
      (agent-shell-org-render--fontify-inline-code
       (car (map-elt inline-code 'body))
       (cdr (map-elt inline-code 'body))))
    (dolist (block source-blocks)
      (agent-shell-org-render--fontify-source-block
       (car (map-elt block 'start))
       (cdr (map-elt block 'start))
       (car (map-elt block 'language))
       (cdr (map-elt block 'language))
       (car (map-elt block 'body))
       (cdr (map-elt block 'body))
       (car (map-elt block 'end))
       (cdr (map-elt block 'end))))
    `((headers . ,headers)
      (bolds . ,bolds)
      (italics . ,italics)
      (links . ,links)
      (strikethroughs . ,strikethroughs)
      (inline-codes . ,inline-codes)
      (source-blocks . ,source-blocks))))

(defun agent-shell-org-render-remove ()
  "Remove all org-render overlays."
  (remove-overlays (point-min) (point-max)
                   'category agent-shell-org-render--overlay-category))

(defun agent-shell-org-render--put (overlay &rest props)
  "Set multiple properties on OVERLAY via PROPS."
  (unless (= (mod (length props) 2) 0)
    (error "Props missing a property or value"))
  (overlay-put overlay 'category agent-shell-org-render--overlay-category)
  (overlay-put overlay 'priority 1000)
  (while props
    (overlay-put overlay (pop props) (pop props))))

;; ─────────────────────────────────────────────
;; Parsers
;; ─────────────────────────────────────────────

(defun agent-shell-org-render--headers (&optional avoid-ranges)
  "Extract markdown headers with AVOID-RANGES."
  (let ((headers '())
        (case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (rx bol (zero-or-more space) (group (one-or-more "#"))
                  (one-or-more space)
                  (group (one-or-more (not (any "\n")))) eol)
              nil t)
        (when-let ((begin (match-beginning 0))
                   (end (match-end 0))
                   (level-start (match-beginning 1))
                   (level-end (match-end 1))
                   (title-start (match-beginning 2))
                   (title-end (match-end 2)))
          (unless (seq-find (lambda (avoided)
                              (and (>= begin (car avoided))
                                   (<= end (cdr avoided))))
                            avoid-ranges)
            (push (list 'start begin
                        'end end
                        'level (cons level-start level-end)
                        'title (cons title-start title-end))
                  headers)))))
    (nreverse headers)))

(defun agent-shell-org-render--bolds (&optional avoid-ranges)
  "Extract markdown bolds with AVOID-RANGES."
  (let ((bolds '())
        (case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (rx (or line-start (syntax whitespace))
                  (group
                   (or (seq "**" (group (one-or-more (not (any "\n*")))) "**")
                       (seq "__" (group (one-or-more (not (any "\n_")))) "__")))
                  (or (syntax punctuation) (syntax whitespace) line-end))
              nil t)
        (when-let ((begin (match-beginning 1))
                   (end (match-end 1))
                   (text-start (or (match-beginning 2) (match-beginning 3)))
                   (text-end (or (match-end 2) (match-end 3))))
          (unless (seq-find (lambda (avoided)
                              (and (>= begin (car avoided))
                                   (<= end (cdr avoided))))
                            avoid-ranges)
            (push (list 'start begin
                        'end end
                        'text (cons text-start text-end))
                  bolds)))))
    (nreverse bolds)))

(defun agent-shell-org-render--italics (&optional avoid-ranges)
  "Extract markdown italics with AVOID-RANGES."
  (let ((italics '())
        (case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (rx (or (group (or bol (one-or-more (any "\n \t")))
                             (group "*")
                             (group (one-or-more (not (any "\n*")))) "*")
                      (group (or bol (one-or-more (any "\n \t")))
                             (group "_")
                             (group (one-or-more (not (any "\n_")))) "_")))
              nil t)
        (when-let ((begin (match-beginning 0))
                   (end (match-end 0))
                   (start-pos (or (match-beginning 2) (match-beginning 5)))
                   (text-start (or (match-beginning 3) (match-beginning 6)))
                   (text-end (or (match-end 3) (match-end 6))))
          (unless (seq-find (lambda (avoided)
                              (and (>= begin (car avoided))
                                   (<= end (cdr avoided))))
                            avoid-ranges)
            (push (list 'start start-pos
                        'end end
                        'text (cons text-start text-end))
                  italics)))))
    (nreverse italics)))

(defun agent-shell-org-render--links (&optional avoid-ranges)
  "Extract markdown links with AVOID-RANGES."
  (let ((links '())
        (case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (rx (seq "["
                       (group (one-or-more (not (any "]"))))
                       "]"
                       "("
                       (group (one-or-more (not (any ")"))))
                       ")"))
              nil t)
        (when-let ((begin (match-beginning 0))
                   (end (match-end 0))
                   (title-start (match-beginning 1))
                   (title-end (match-end 1))
                   (url-start (match-beginning 2))
                   (url-end (match-end 2)))
          (unless (or (eq (char-before begin) ?!)
                      (seq-find (lambda (avoided)
                                  (and (>= begin (car avoided))
                                       (<= end (cdr avoided))))
                                avoid-ranges))
            (push (list 'start begin
                        'end end
                        'title (cons title-start title-end)
                        'url (cons url-start url-end))
                  links)))))
    (nreverse links)))

(defun agent-shell-org-render--strikethroughs (&optional avoid-ranges)
  "Extract markdown strikethroughs with AVOID-RANGES."
  (let ((strikethroughs '())
        (case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (rx "~~" (group (one-or-more (not (any "\n~")))) "~~")
              nil t)
        (when-let ((begin (match-beginning 0))
                   (end (match-end 0))
                   (text-start (match-beginning 1))
                   (text-end (match-end 1)))
          (unless (seq-find (lambda (avoided)
                              (and (>= begin (car avoided))
                                   (<= end (cdr avoided))))
                            avoid-ranges)
            (push (list 'start begin
                        'end end
                        'text (cons text-start text-end))
                  strikethroughs)))))
    (nreverse strikethroughs)))

(defun agent-shell-org-render--inline-codes (&optional avoid-ranges)
  "Extract inline code spans with AVOID-RANGES."
  (let ((codes '())
        (case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "`\\([^`\n]+\\)`" nil t)
        (when-let ((begin (match-beginning 0))
                   (end (match-end 0))
                   (body-start (match-beginning 1))
                   (body-end (match-end 1)))
          (if-let ((avoided (seq-find (lambda (avoided)
                                        (not (or (> begin (cdr avoided))
                                                 (< end (car avoided)))))
                                      avoid-ranges)))
              (goto-char (1+ (cdr avoided)))
            (push (list 'body (cons body-start body-end)) codes)))))
    (nreverse codes)))

(defun agent-shell-org-render--source-blocks ()
  "Extract all source blocks in buffer."
  (let ((blocks '())
        (case-fold-search nil))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (when (looking-at "^\\(?:[ \\t]*\\)```\\(?:[ \\t]*\\)\\([a-zA-Z0-9+#-]*\\)[ \\t]*[\n]")
          (let ((lang-start (match-beginning 1))
                (lang-end (match-end 1))
                (quotes1-start (match-beginning 0))
                (quotes1-end (match-end 0))
                (body-start (point)))
            (forward-line)
            (let ((body-begin body-start))
              (while (and (not (eobp)) (not (looking-at "^\\(?:[ \\t]*\\)```\\(?:[ \\t]*\\)$")))
                (forward-line))
              (unless (eobp)
                (let ((body-end (point))
                      (quotes2-start (match-beginning 0))
                      (quotes2-end (match-end 0)))
                  (push (list 'start (cons quotes1-start quotes1-end)
                              'end (cons quotes2-start quotes2-end)
                              'language (when (and lang-start lang-end)
                                          (cons lang-start lang-end))
                              'body (cons body-begin body-end))
                        blocks)
                  (forward-line))))))
        (unless (eobp) (forward-line))))
    (nreverse blocks)))

(defun agent-shell-org-render--fontify-header (_start end level-start level-end title-start title-end)
  "Fontify a markdown header as org-style.
Use START END LEVEL-START LEVEL-END TITLE-START TITLE-END."
  ;; Hide markup before (## → invisible)
  (agent-shell-org-render--put
   (make-overlay level-start title-start)
   'evaporate t
   'org-render-markup-type 'header
   'invisible t)
  ;; Show title as org-level face
  (agent-shell-org-render--put
   (make-overlay title-start title-end)
   'evaporate t
   'face
   (cond ((eq (- level-end level-start) 1) 'org-level-1)
         ((eq (- level-end level-start) 2) 'org-level-2)
         ((eq (- level-end level-start) 3) 'org-level-3)
         ((eq (- level-end level-start) 4) 'org-level-4)
         ((eq (- level-end level-start) 5) 'org-level-5)
         ((eq (- level-end level-start) 6) 'org-level-6)
         ((eq (- level-end level-start) 7) 'org-level-7)
         ((eq (- level-end level-start) 8) 'org-level-8)
         (t 'org-level-1)))
  ;; Add newline after if needed
  (when (< end (point-max))
    (save-excursion
      (goto-char end)
      (unless (looking-at-p "\n")
        (agent-shell-org-render--put
         (make-overlay end end)
         'evaporate t
         'org-render-markup-type 'header
         'after-string "\n")))))

(defun agent-shell-org-render--fontify-bold (start end text-start text-end)
  "Fontify a markdown bold as org-style.
Use START END TEXT-START TEXT-END."
  ;; Hide markup before (** → invisible)
  (agent-shell-org-render--put
   (make-overlay start text-start)
   'evaporate t
   'org-render-markup-type 'bold
   'invisible t)
  ;; Show text as org-bold face
  (agent-shell-org-render--put
   (make-overlay text-start text-end)
   'evaporate t
   'face 'bold)
  ;; Hide markup after
  (agent-shell-org-render--put
   (make-overlay text-end end)
   'evaporate t
   'org-render-markup-type 'bold
   'invisible t))

(defun agent-shell-org-render--fontify-italic (start end text-start text-end)
  "Fontify a markdown italic as org-style.
Use START END TEXT-START TEXT-END."
  ;; Hide markup before (* → invisible)
  (agent-shell-org-render--put
   (make-overlay start text-start)
   'evaporate t
   'org-render-markup-type 'italic
   'invisible t)
  ;; Show text as org-italic face
  (agent-shell-org-render--put
   (make-overlay text-start text-end)
   'evaporate t
   'face 'italic)
  ;; Hide markup after
  (agent-shell-org-render--put
   (make-overlay text-end end)
   'evaporate t
   'org-render-markup-type 'italic
   'invisible t))

(defun agent-shell-org-render--fontify-link (start end title-start title-end url-start url-end)
  "Fontify a markdown link as org-style.
Use START END TITLE-START TITLE-END URL-START URL-END."
  ;; Hide markup before
  (agent-shell-org-render--put
   (make-overlay start title-start)
   'evaporate t
   'org-render-markup-type 'link
   'invisible t)
  ;; Show title as link
  (agent-shell-org-render--put
   (make-overlay title-start title-end)
   'evaporate t
   'face 'org-link)
  ;; Hide markup after
  (agent-shell-org-render--put
   (make-overlay title-end end)
   'evaporate t
   'org-render-markup-type 'link
   'invisible t))

(defun agent-shell-org-render--fontify-strikethrough (start end text-start text-end)
  "Fontify a markdown strikethrough as org-style.
Use START END TEXT-START TEXT-END."
  ;; Hide markup before
  (agent-shell-org-render--put
   (make-overlay start text-start)
   'evaporate t
   'org-render-markup-type 'strikethrough
   'invisible t)
  ;; Show text as strikethrough
  (agent-shell-org-render--put
   (make-overlay text-start text-end)
   'evaporate t
   'face '(:strike-through t))
  ;; Hide markup after
  (agent-shell-org-render--put
   (make-overlay text-end end)
   'evaporate t
   'org-render-markup-type 'strikethrough
   'invisible t))

(defun agent-shell-org-render--fontify-inline-code (body-start body-end)
  "Fontify inline code as org-style.
Use BODY-START BODY-END."
  ;; Hide backtick before
  (agent-shell-org-render--put
   (make-overlay (1- body-start) body-start)
   'evaporate t
   'org-render-markup-type 'inline-code
   'invisible t)
  ;; Hide backtick after
  (agent-shell-org-render--put
   (make-overlay body-end (1+ body-end))
   'evaporate t
   'org-render-markup-type 'inline-code
   'invisible t)
  ;; Show code body
  (agent-shell-org-render--put
   (make-overlay body-start body-end)
   'evaporate t
   'face 'font-lock-doc-markup-face))

(defun agent-shell-org-render--fontify-source-block (quotes1-start quotes1-end lang-start lang-end body-start body-end quotes2-start quotes2-end)
  "Fontify a source block as org-style.
Use QUOTES1-START QUOTES1-END LANG-START LANG-END BODY-START BODY-END QUOTES2-START QUOTES2-END."
  ;; Replace ``` with #+begin_src
  (agent-shell-org-render--put
   (make-overlay quotes1-start quotes1-end)
   'evaporate t
   'org-render-markup-type 'fence
   'display "#+begin_src")
  ;; Replace closing ``` with #+end_src
  (agent-shell-org-render--put
   (make-overlay quotes2-start quotes2-end)
   'evaporate t
   'org-render-markup-type 'fence
   'display "#+end_src")
  ;; Show language
  (unless (= lang-start lang-end)
    (agent-shell-org-render--put
     (make-overlay lang-start lang-end)
     'evaporate t
     'org-render-markup-type 'language
     'face '(:box t))
    (agent-shell-org-render--put
     (make-overlay lang-end (1+ lang-end))
     'evaporate t
     'org-render-markup-type 'language
     'display "\n\n"))
  ;; Fontify body
  (let ((lang (buffer-substring-no-properties lang-start lang-end))
        (string (buffer-substring-no-properties body-start body-end)))
    (let ((lang-mode (intern (concat (downcase (string-trim lang)) "-mode"))))
      (if (fboundp lang-mode)
          (let ((propertized
                 (with-current-buffer
                     (get-buffer-create
                      (format " *org-render-fontification:%s*" lang-mode))
                   (let ((inhibit-modification-hooks nil)
                         (inhibit-message t))
                     (erase-buffer)
                     (insert string " ")
                     (funcall lang-mode)
                     (font-lock-ensure))
                   (buffer-string)))
                (len (- body-end body-start))
                (pos 0))
            (setq len (min len (length propertized)))
            (while (< pos len)
              (let ((next (next-single-property-change pos 'face propertized len))
                    (face (get-text-property pos 'face propertized)))
                (when face
                  (agent-shell-org-render--put
                   (make-overlay (+ body-start pos) (+ body-start next))
                   'evaporate t
                   'face face))
                (setq pos next))))
        (agent-shell-org-render--put
         (make-overlay body-start body-end)
         'evaporate t
         'face 'font-lock-doc-markup-face)))))

;; ─────────────────────────────────────────────
;; Minor Mode
;; ─────────────────────────────────────────────

(define-minor-mode agent-shell-org-render-mode
  "Toggle org-style overlay rendering.
When enabled, markdown syntax is rendered using org-style overlays."
  :global t
  :lighter " OrgRender"
  (if agent-shell-org-render-mode
      (progn
        (agent-shell-org-render--install-advice)
        (message "agent-shell-org-render: enabled"))
    (agent-shell-org-render--uninstall-advice)
    (message "agent-shell-org-render: disabled")))

(defun agent-shell-org-render-toggle ()
  "Toggle org-style rendering in current buffer."
  (interactive)
  (agent-shell-org-render-mode (if agent-shell-org-render-mode -1 1)))

;; ─────────────────────────────────────────────
;; Advice Hooks
;; ─────────────────────────────────────────────

(defvar agent-shell-org-render--advice-installed nil
  "Whether advice hooks are currently installed.")

(defun agent-shell-org-render--install-advice ()
  "Install advice hooks for agent-shell viewport integration."
  (unless agent-shell-org-render--advice-installed
    (advice-add 'agent-shell-viewport--initialize
                :after #'agent-shell-org-render--apply)
    (advice-add 'agent-shell-viewport-refresh
                :after #'agent-shell-org-render--apply)
    (setq agent-shell-org-render--advice-installed t)))

(defun agent-shell-org-render--uninstall-advice ()
  "Uninstall advice hooks."
  (when agent-shell-org-render--advice-installed
    (advice-remove 'agent-shell-viewport--initialize
                   #'agent-shell-org-render--apply)
    (advice-remove 'agent-shell-viewport-refresh
                   #'agent-shell-org-render--apply)
    (setq agent-shell-org-render--advice-installed nil)))

(defun agent-shell-org-render--apply (&rest _)
  "Apply org-style overlays after viewport initialization."
  (when (and agent-shell-org-render-mode
             agent-shell-org-render-auto-apply-in-viewport
             (derived-mode-p 'agent-shell-viewport-view-mode))
    (agent-shell-org-render-put)))

;; ─────────────────────────────────────────────
;; Image Rendering (Optional)
;; ─────────────────────────────────────────────

(defun agent-shell-org-render--latex-available-p ()
  "Check if LaTeX image rendering is available."
  (and agent-shell-org-render-latex-process
       (executable-find (if (eq agent-shell-org-render-latex-process 'dvipng)
                           "latex"
                         "latex"))))

(defun agent-shell-org-render--mermaid-available-p ()
  "Check if Mermaid rendering is available."
  (and agent-shell-org-render-mermaid-backend
       (or (and (eq agent-shell-org-render-mermaid-backend 'cli)
                (executable-find "mmdc"))
           (eq agent-shell-org-render-mermaid-backend 'api))))

(defun agent-shell-org-render--render-latex-inline (start end latex-string)
  "Render LaTeX inline math as image overlay.
START END are buffer positions, LATEX-STRING is the math content."
  (when (agent-shell-org-render--latex-available-p)
    ;; Stub: would generate image and apply display overlay
    (agent-shell-org-render--put
     (make-overlay start end)
     'evaporate t
     'org-render-markup-type 'latex
     'display (format "[LaTeX: %s]" (substring latex-string 0 (min 20 (length latex-string)))))))

(defun agent-shell-org-render--render-mermaid-block (start end body)
  "Render Mermaid block as image overlay.
START END are buffer positions, BODY is the diagram source."
  (when (agent-shell-org-render--mermaid-available-p)
    ;; Stub: would generate image and apply display overlay
    (agent-shell-org-render--put
     (make-overlay start end)
     'evaporate t
     'org-render-markup-type 'mermaid
     'display "[Mermaid diagram]")))

(defun agent-shell-org-render--render-ditaa-block (start end body)
  "Render Ditaa block as image overlay.
START END are buffer positions, BODY is the diagram source."
  (when (executable-find "ditaa")
    ;; Stub: would generate image and apply display overlay
    (agent-shell-org-render--put
     (make-overlay start end)
     'evaporate t
     'org-render-markup-type 'ditaa
     'display "[Ditaa diagram]")))

;; ─────────────────────────────────────────────
;; Cursor Reveal (Optional)
;; ─────────────────────────────────────────────

(defun agent-shell-org-render--cursor-sensor-function (window prev-loc next-loc)
  "Cursor sensor function to reveal markup when cursor enters.
WINDOW PREV-LOC NEXT-LOC are cursor sensor arguments."
  (let ((inhibit-read-only t))
    (when next-loc
      (dolist (ov (overlays-at next-loc))
        (when (eq (overlay-get ov 'org-render-markup-type) 'header)
          (overlay-put ov 'invisible nil))))
    (when prev-loc
      (dolist (ov (overlays-at prev-loc))
        (when (eq (overlay-get ov 'org-render-markup-type) 'header)
          (overlay-put ov 'invisible t))))))

(defun agent-shell-org-render--enable-cursor-sensor ()
  "Enable cursor-sensor-functions for reveal behavior."
  (add-hook 'post-command-hook #'agent-shell-org-render--cursor-reveal nil t))

(defun agent-shell-org-render--disable-cursor-sensor ()
  "Disable cursor-sensor-functions."
  (remove-hook 'post-command-hook #'agent-shell-org-render--cursor-reveal t))

(defun agent-shell-org-render--cursor-reveal ()
  "Reveal markup under cursor temporarily."
  (let ((ovs (overlays-at (point))))
    (dolist (ov ovs)
      (when (overlay-get ov 'org-render-hidden-markup)
        (overlay-put ov 'invisible nil)))))

;; ─────────────────────────────────────────────
;; Provide
;; ─────────────────────────────────────────────

(provide 'agent-shell-org-render)

;;; agent-shell-org-render.el ends here
