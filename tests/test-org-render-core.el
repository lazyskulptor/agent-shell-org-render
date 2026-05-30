;;; test-org-render-core.el --- Unit tests for agent-shell-org-render  -*- lexical-binding: t -*-

(require 'ert)
(require 'agent-shell-org-render)

;; ─────────────────────────────────────────────
;; Header Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-header-h1 ()
  "# Title should get org-level-1 face"
  (with-temp-buffer
    (insert "# Title\n")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (forward-line 0)
    (search-forward "Title")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'org-level-1))
                        ovs)))))

(ert-deftest org-render-header-h2 ()
  "## Title should get org-level-2 face"
  (with-temp-buffer
    (insert "## Title\n")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (forward-line 0)
    (search-forward "Title")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'org-level-2))
                        ovs)))))

(ert-deftest org-render-header-h3 ()
  "### Title should get org-level-3 face"
  (with-temp-buffer
    (insert "### Title\n")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (forward-line 0)
    (search-forward "Title")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'org-level-3))
                        ovs)))))

(ert-deftest org-render-header-markup-hidden ()
  "## markup should be invisible"
  (with-temp-buffer
    (insert "## Title\n")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "## ")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'invisible) t))
                        ovs)))))

;; ─────────────────────────────────────────────
;; Bold Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-bold-basic ()
  "**bold** should get bold face"
  (with-temp-buffer
    (insert "**bold**")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "bold")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'bold))
                        ovs)))))

(ert-deftest org-render-bold-underscore ()
  "__bold__ should get bold face"
  (with-temp-buffer
    (insert "__bold__")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "bold")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'bold))
                        ovs)))))

(ert-deftest org-render-bold-markup-hidden ()
  "** markup should be invisible"
  (with-temp-buffer
    (insert "**bold**")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "**")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'invisible) t))
                        ovs)))))

;; ─────────────────────────────────────────────
;; Italic Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-italic-basic ()
  "*italic* should get italic face"
  (with-temp-buffer
    (insert "*italic*")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "italic")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'italic))
                        ovs)))))

;; ─────────────────────────────────────────────
;; Inline Code Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-inline-code-basic ()
  "`code` should get font-lock-doc-markup-face"
  (with-temp-buffer
    (insert "`code`")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "code")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'font-lock-doc-markup-face))
                        ovs)))))

(ert-deftest org-render-inline-code-backticks-hidden ()
  "Backticks should be invisible"
  (with-temp-buffer
    (insert "`code`")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "`")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'invisible) t))
                        ovs)))))

;; ─────────────────────────────────────────────
;; Link Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-link-basic ()
  "[text](url) should get org-link face"
  (with-temp-buffer
    (insert "[text](http://example.com)")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "text")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'org-link))
                        ovs)))))

(ert-deftest org-render-link-markup-hidden ()
  "[ ]( ) markup should be invisible"
  (with-temp-buffer
    (insert "[text](http://example.com)")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "[")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'invisible) t))
                        ovs)))))

;; ─────────────────────────────────────────────
;; Strikethrough Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-strikethrough-basic ()
  "~~text~~ should get strike-through face"
  (with-temp-buffer
    (insert "~~text~~")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "text")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (equal (overlay-get ov 'face) '(:strike-through t)))
                        ovs)))))

;; ─────────────────────────────────────────────
;; Source Block Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-source-block-basic ()
  "``` should be replaced with #+begin_src/#+end_src display"
  (with-temp-buffer
    (insert "```elisp\n(+ 1 2)\n```")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "```")
    (backward-char)
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (equal (overlay-get ov 'display) "#+begin_src"))
                        ovs)))))

;; ─────────────────────────────────────────────
;; Remove Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-remove ()
  "agent-shell-org-render-remove should remove all overlays"
  (with-temp-buffer
    (insert "**bold** and `code`\n")
    (agent-shell-org-render-put)
    (should (> (length (overlays-in (point-min) (point-max))) 0))
    (agent-shell-org-render-remove)
    (should (= (length (overlays-in (point-min) (point-max))) 0))))

;; ─────────────────────────────────────────────
;; Avoid Ranges Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-avoid-ranges-inline-code-in-block ()
  "Inline code inside source blocks should not be overlaid"
  (with-temp-buffer
    (insert "```elisp\n`code`\n```")
    (agent-shell-org-render-put)
    ;; The ` inside the block should not have inline-code overlays
    (goto-char (point-min))
    (search-forward "`code`")
    (backward-char 6)
    (let ((ovs (overlays-at (point))))
      ;; Should not find inline-code markup overlays on the backticks inside block
      (should (not (seq-find (lambda (ov)
                               (eq (overlay-get ov 'org-render-markup-type)
                                   'inline-code))
                             ovs))))))

;; ─────────────────────────────────────────────
;; Custom Variables Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-custom-vars-exist ()
  "All custom variables should be defined"
  (should (boundp 'agent-shell-org-render-enable-images))
  (should (boundp 'agent-shell-org-render-mermaid-backend))
  (should (boundp 'agent-shell-org-render-latex-process))
  (should (boundp 'agent-shell-org-render-auto-apply-in-viewport)))

(ert-deftest org-render-custom-var-defaults ()
  "Custom variables should have correct defaults"
  (should (eq agent-shell-org-render-enable-images t))
  (should (eq agent-shell-org-render-mermaid-backend 'api))
  (should (eq agent-shell-org-render-latex-process 'dvipng))
  (should (eq agent-shell-org-render-auto-apply-in-viewport t)))

;; ─────────────────────────────────────────────
;; Package Load Test
;; ─────────────────────────────────────────────

(ert-deftest org-render-package-loads ()
  "Package should load without errors"
  (should (require 'agent-shell-org-render nil t)))

(ert-deftest org-render-provide-symbol ()
  "Package should provide 'agent-shell-org-render"
  (should (featurep 'agent-shell-org-render)))

(provide 'test-org-render-core)
;;; test-org-render-core.el ends here
