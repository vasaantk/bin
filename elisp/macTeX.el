;;; package --- Summary

;;; Commentary:
;; Latex specificts used on my PhD macintosh.
;;

;;;========================================================
;;; Code:
;;
(add-to-list 'load-path "/usr/local/share/emacs/site-lisp")
(add-to-list 'load-path "/Library/TeX/texbin/")

(require 'tex-site)

;; Use Skim as viewer, enable source <-> PDF sync
;; make latexmk available via C-c C-c
;; Note: SyncTeX is setup via ~/.latexmkrc (see below)
(add-hook 'LaTeX-mode-hook (lambda ()
                             (push
                              '("latexmk" "latexmk -pdf %s" TeX-run-TeX nil t
                                :help "Run latexmk on file")
                              TeX-command-list)))
(add-hook 'TeX-mode-hook '(lambda () (setq TeX-command-default "latexmk")))

;; use Skim as default pdf viewer
;; Skim's displayline is used for forward search (from .tex to .pdf)
;; option -b highlights the current line; option -g opens Skim in the background
(setq TeX-view-program-selection '((output-pdf "PDF Viewer")))
(setq TeX-view-program-list
      '(("PDF Viewer" "/Applications/Skim.app/Contents/SharedSupport/displayline -b -g %n %o %b")))

;; (server-start); start emacs in server mode so that skim can talk to it

;; To get PATH into Emacs.app
(getenv "PATH")
(setenv "PATH"
        (concat
         "/Library/TeX/texbin/:"
         (getenv "PATH")))

(provide 'macTeX)
;;; macTeX.el ends here
