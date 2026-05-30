;;; test-e2e-docker.el --- Docker E2E tests for agent-shell-org-render  -*- lexical-binding: t -*-

(require 'ert)
(require 'agent-shell-org-render)

;; ─────────────────────────────────────────────
;; Mock agent-shell functions
;; ─────────────────────────────────────────────

(defun agent-shell-viewport--initialize (&rest _) nil)
(defun agent-shell-viewport-refresh (&rest _) nil)
(defun agent-shell--shell-buffer () nil)
(defun markdown-overlays-put () nil)

;; ─────────────────────────────────────────────
;; Full Render E2E Test
;; ─────────────────────────────────────────────

(ert-deftest e2e-full-render ()
  "Full markdown content should render with org-style overlays"
  (with-temp-buffer
    (insert "# Main Title\n")
    (insert "## Subtitle\n")
    (insert "### Sub-subtitle\n")
    (insert "#### Level 4\n")
    (insert "\n")
    (insert "This is **bold** and *italic* text.\n")
    (insert "Here is `inline code` and ~~strikethrough~~.\n")
    (insert "\n")
    (insert "[A link](http://example.com)\n")
    (insert "\n")
    (insert "```elisp\n")
    (insert "(defun hello ()\n")
    (insert "  (message \"Hello\"))\n")
    (insert "```\n")
    (insert "\n")
    (insert "Another `code` snippet here.\n")
    
    (agent-shell-org-render-put)
    
    (let ((overlays (overlays-in (point-min) (point-max))))
      (should (> (length overlays) 10))
      
      ;; Verify header overlays
      (goto-char (point-min))
      (search-forward "Main Title")
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'org-level-1))
                        (overlays-at (point))))
      
      ;; Verify bold overlays
      (goto-char (point-min))
      (search-forward "bold")
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'bold))
                        (overlays-at (point))))
      
      ;; Verify inline code overlays
      (goto-char (point-min))
      (search-forward "inline code")
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'font-lock-doc-markup-face))
                        (overlays-at (point)))))))

;; ─────────────────────────────────────────────
;; Source Block E2E Test
;; ─────────────────────────────────────────────

(ert-deftest e2e-source-block-render ()
  "Source blocks should render with #+begin_src/#+end_src display"
  (with-temp-buffer
    (insert "```python\n")
    (insert "print('hello')\n")
    (insert "```\n")
    
    (agent-shell-org-render-put)
    
    (goto-char (point-min))
    (search-forward "```")
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (equal (overlay-get ov 'display) "#+begin_src"))
                        ovs)))))

;; ─────────────────────────────────────────────
;; Link E2E Test
;; ─────────────────────────────────────────────

(ert-deftest e2e-link-render ()
  "Links should render with org-link face"
  (with-temp-buffer
    (insert "[Example](http://example.com)")
    
    (agent-shell-org-render-put)
    
    (goto-char (point-min))
    (search-forward "Example")
    (let ((ovs (overlays-at (point))))
      (should ovs)
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'org-link))
                        ovs)))))

;; ─────────────────────────────────────────────
;; Toggle E2E Test
;; ─────────────────────────────────────────────

(ert-deftest e2e-toggle-works ()
  "Toggle should enable/disable org rendering"
  (agent-shell-org-render-mode -1)
  (with-temp-buffer
    (insert "**bold**")
    (agent-shell-org-render-put)
    (goto-char (point-min))
    (search-forward "bold")
    (let ((ovs (overlays-at (point))))
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'bold))
                        ovs))))
  (agent-shell-org-render-mode 1))

;; ─────────────────────────────────────────────
;; Overlay Properties E2E Test
;; ─────────────────────────────────────────────

(ert-deftest e2e-overlay-properties ()
  "All overlays should have correct properties"
  (with-temp-buffer
    (insert "**bold** *italic* `code`\n")
    (agent-shell-org-render-put)
    
    (dolist (ov (overlays-in (point-min) (point-max)))
      (should (eq (overlay-get ov 'category) 'agent-shell-org-render))
      (should (eq (overlay-get ov 'evaporate) t)))))

;; ─────────────────────────────────────────────
;; Avoid Ranges E2E Test
;; ─────────────────────────────────────────────

(ert-deftest e2e-avoid-ranges ()
  "Content inside source blocks should not be overlaid"
  (with-temp-buffer
    (insert "```elisp\n")
    (insert "`code` inside block\n")
    (insert "```\n")
    (insert "`code` outside block\n")
    
    (agent-shell-org-render-put)
    
    ;; Find inline code outside block
    (goto-char (point-min))
    (search-forward "`code` outside")
    (let ((ovs (overlays-at (point))))
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'category) 'agent-shell-org-render))
                        ovs)))))

(provide 'test-e2e-docker)
;;; test-e2e-docker.el ends here
