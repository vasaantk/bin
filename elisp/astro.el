;;; package --- Summary

;;; Commentary:
;; Vasaant's handy-dandy elisp functions
;;

;;;========================================================
;;; Code:
;;
(defun toch ()
  "Execute toch within a Windows Emacs buffer via WSL2."
  (interactive)
  (setq exec-toch (concat "/mnt/c/Users/VasaantK/OneDrive\\ -\\ Echoview\\ Software/bin/bash/toch " (buffer-name)))
  (let ((output (string-trim-right (shell-command-to-string (concat "bash.exe -c '" exec-toch "'")))))
    (insert output)))

(defun get-htm-filenames ()
  (interactive)
  (setq get-help-filename-command (format "%s" "find /mnt/c/Users/VasaantK/echoviewhelp/contents -type f -iname \"*.htm\" -exec basename {} \\; "))
  (setq bash-command (format "%s" "bash.exe -c"))
  (let* ((db-contents
          (shell-command-to-string (format "%s '%s'" bash-command get-help-filename-command)))
         (db-list (split-string db-contents "\n" t)))
    (let ((input (completing-read "Page file name: " db-list)))
      (format "%s" input))))

(defun elink (goToFileName &optional linkName)
  "Execute linker within a Windows Emacs buffer via WSL2."
  (interactive
   (list (get-htm-filenames)
         (if (region-active-p)
             (buffer-substring-no-properties (region-beginning) (region-end)))))
  (if (region-active-p)
      (kill-region (region-beginning) (region-end)))
  (unless linkName
    (setq linkName (read-from-minibuffer "Link: ")))
  (setq linker-path (format "%s" "/mnt/c/Users/VasaantK/OneDrive\\ -\\ Echoview\\ Software/bin/bash/linker"))
  (setq file-with-ext (format "%s" goToFileName))
  (setq linker-command (format "%s %s %s" linker-path (buffer-name) file-with-ext))
  (setq bash-command (format "%s" "bash.exe -c"))
  (setq output (replace-regexp-in-string "\n" "" (shell-command-to-string (format "%s '%s'" bash-command linker-command))))
  (setq result (format "%s%s%s%s%s" "<a href=\"" output "\">" linkName "</a>"))
  (insert result))

(defun doco ()
  "Open the current file or `dired' marked files in Google Chrome browser.
Work in Windows, macOS, linux.
URL `http://ergoemacs.org/emacs/emacs_dired_open_file_in_ext_apps.html'
Version 2019-11-10"
  (interactive)
  (let* (
         ($file-list
          (if (string-equal major-mode "dired-mode")
              (dired-get-marked-files)
            (list (buffer-file-name))))
         ($do-it-p (if (<= (length $file-list) 5)
                       t
                     (y-or-n-p "Open more than 5 files? "))))
    (when $do-it-p
      (cond
       ((string-equal system-type "darwin")
        (mapc
         (lambda ($fpath)
           (shell-command
            (format "open -a /Applications/Google\\ Chrome.app \"%s\"" $fpath)))
         $file-list))
       ((string-equal system-type "windows-nt")
        ;; "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" 2019-11-09
        (let ((process-connection-type nil))
          (mapc
           (lambda ($fpath)
             (start-process "" nil "powershell" "start-process" "chrome" $fpath ))
           $file-list)))
       ((string-equal system-type "gnu/linux")
        (mapc
         (lambda ($fpath)
           (shell-command (format "google-chrome-stable \"%s\"" $fpath)))
         $file-list))))))


(defun date ()
  (backward-kill-sexp)
  (insert (shell-command-to-string "echo -n $(date +%A,%t%d%t%B%t%Y,%t%H:%M%t%p)")))


(defun time ()
  (backward-kill-sexp)
  (insert (shell-command-to-string "echo -n $(date +%H:%M%t%p)")))


(defun deg2rad (ANGLE)
"Convert an angle from degrees to radians."
(* ANGLE
   (/ pi 180.0)))


(defun rad2deg (ANGLE)
"Convert an angle from radians to degrees."
(* ANGLE
   (/ 180.0 pi)))


(defun deg2ra (ANGLE)
  "Convert an angle from degrees to right ascension."
  (if (< ANGLE 360.0)
      (progn
        (setq HH (floor (/ ANGLE 15)))
        (setq MM (floor (* (- ANGLE (* 15 HH)) 4)))
        (setq SS (* (- (* 4 ANGLE) (* 60 HH) MM) 60))
        (message "%02d %02d %.5f" HH MM SS))
    (message "%f is more than 360 degrees" ANGLE)))


(defun deg2dec (ANGLE)
  "Convert an angle from degrees to right ascension."
  (if (< ANGLE 0)
      (setq NEG -1)
    (setq NEG  1))
  (setq DEG (abs ANGLE))
  (if (< DEG 180.0)
      (progn
        (if (> DEG 90.0)
            (progn
              (setq DEG (- DEG 90))
              (setq NEG -1)
              ))
        (setq HH (floor DEG))
        (setq MM (floor (* (- DEG HH) 60)))
        (setq SS (* (- (* (- DEG HH) 60) MM) 60))
        (if (> NEG 0)
            (message "%02d %02d %.5f" HH MM SS)
          (message "-%02d %02d %.5f" HH MM SS)))
    (message "abs(%f) is more than 180 degrees." ANGLE)))


(defun ra2deg (HRS MIN SEC)
  "Convert an angle from right ascension to degrees"
  (setq HH (* (float HRS) 15.0))
  (setq MM (* (/ (float MIN) 60.0) 15.0))
  (setq SS (* (/ (float SEC) 3600.0) 15.0))
  (setq DEG (+ HH MM SS)))


(defun dec2deg (HRS MIN SEC)
  "Convert an angle from declination to degrees"
  (setq HH (float (abs HRS)))
  (setq MM (/ (float MIN) 60.0))
  (setq SS (/ (float SEC) 3600.0))
  (setq DEG (+ HH MM SS))
  (if (< HRS 0)
      (setq DEG (- DEG))
    (setq DEG DEG)))
