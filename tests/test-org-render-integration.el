;;; test-org-render-integration.el --- Integration tests for agent-shell-org-render  -*- lexical-binding: t -*-

(require 'ert)
(require 'agent-shell-org-render)

;; ─────────────────────────────────────────────
;; Mock agent-shell functions
;; ─────────────────────────────────────────────

(defun agent-shell-viewport--initialize (&rest _)
  "Mock viewport initialize."
  nil)

(defun agent-shell-viewport-refresh (&rest _)
  "Mock viewport refresh."
  nil)

(defun agent-shell--shell-buffer ()
  "Mock shell buffer."
  nil)

(defun markdown-overlays-put ()
  "Mock markdown overlays put."
  nil)

;; ─────────────────────────────────────────────
;; Advice Integration Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-advice-installs ()
  "Advice should be installed when minor mode is enabled"
  (agent-shell-org-render-mode 1)
  (should agent-shell-org-render--advice-installed)
  (agent-shell-org-render-mode -1))

(ert-deftest org-render-advice-uninstalls ()
  "Advice should be removed when minor mode is disabled"
  (agent-shell-org-render-mode 1)
  (agent-shell-org-render-mode -1)
  (should (not agent-shell-org-render--advice-installed)))

(ert-deftest org-render-advice-applies-overlay ()
  "Advice should apply overlays after viewport init"
  (agent-shell-org-render-mode 1)
  (with-temp-buffer
    (agent-shell-viewport-view-mode)
    (insert "## Test Header\n")
    (agent-shell-org-render--apply)
    (let ((overlays (overlays-in (point-min) (point-max))))
      (should (> (length overlays) 0))))
  (agent-shell-org-render-mode -1))

;; ─────────────────────────────────────────────
;; Toggle Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-toggle-enables ()
  "Toggle should enable when disabled"
  (agent-shell-org-render-mode -1)
  (agent-shell-org-render-toggle)
  (should agent-shell-org-render-mode)
  (agent-shell-org-render-mode -1))

(ert-deftest org-render-toggle-disables ()
  "Toggle should disable when enabled"
  (agent-shell-org-render-mode 1)
  (agent-shell-org-render-toggle)
  (should (not agent-shell-org-render-mode)))

;; ─────────────────────────────────────────────
;; Full Content Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-full-markdown-content ()
  "Full markdown content should render with overlays"
  (with-temp-buffer
    (insert "# Main Title\n")
    (insert "## Subtitle\n")
    (insert "### Sub-subtitle\n")
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
      
      ;; Check header overlays
      (goto-char (point-min))
      (search-forward "Main Title")
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'org-level-1))
                        (overlays-at (point))))
      
      ;; Check bold overlays
      (goto-char (point-min))
      (search-forward "bold")
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'bold))
                        (overlays-at (point))))
      
      ;; Check inline code overlays
      (goto-char (point-min))
      (search-forward "inline code")
      (should (seq-find (lambda (ov)
                          (eq (overlay-get ov 'face) 'font-lock-doc-markup-face))
                        (overlays-at (point)))))))

;; ─────────────────────────────────────────────
;; Overlay Category Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-overlay-category ()
  "All overlays should have correct category"
  (with-temp-buffer
    (insert "**bold** and `code`\n")
    (agent-shell-org-render-put)
    (dolist (ov (overlays-in (point-min) (point-max)))
      (should (eq (overlay-get ov 'category)
                  'agent-shell-org-render)))))

;; ─────────────────────────────────────────────
;; Evaporate Tests
;; ─────────────────────────────────────────────

(ert-deftest org-render-overlay-evaporate ()
  "All overlays should have evaporate set to t"
  (with-temp-buffer
    (insert "**bold** and `code`\n")
    (agent-shell-org-render-put)
    (dolist (ov (overlays-in (point-min) (point-max)))
      (should (eq (overlay-get ov 'evaporate) t)))))

(provide 'test-org-render-integration)
;;; test-org-render-integration.el ends here
