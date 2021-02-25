;;; package --- Summary

;;; Commentary:
;; Vasaant's handy-dandy elisp functions
;;

;;;========================================================
;;; Code:
;;
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

(defun baseline (antenna)
"Determine the number of baselines of an interferometer."
(/ (- (* antenna antenna ) antenna) 2.0))

(defun date ()
  (backward-kill-sexp)
  (insert (shell-command-to-string "echo %date% %time:~0,5%"))
  (delete-backward-char 1))

(defun time ()
  (backward-kill-sexp)
  (insert (shell-command-to-string "echo %time:~0,5%"))
  (delete-backward-char 1))

(defun deg2rad (ANGLE)
"Convert an angle from degrees to radians."
(* ANGLE
   (/ pi 180.0)))

(defun rad2deg (ANGLE)
"Convert an angle from radians to degrees."
(* ANGLE
   (/ 180.0 pi)))

(defun asec2deg (ANGLE)
"Convert an angle from arcseconds to degrees."
(/ ANGLE 3600.0))

(defun amin2deg (ANGLE)
"Convert an angle from arcminutes to degrees."
(/ ANGLE 60.0))

(defun deg2amin (ANGLE)
"Convert an angle from degrees to arcminutes."
(* ANGLE 60.0))

(defun deg2asec (ANGLE)
"Convert an angle from degrees to arcseconds."
(* ANGLE 3600.0))

(defun asec2rad (ANGLE)
"Convert an angle from arcseconds to radians."
(deg2rad (asec2deg ANGLE)))

(defun amin2rad (ANGLE)
"Convert an angle from arcminutes to radians."
(deg2rad (amin2deg ANGLE)))

(defun rad2asec (ANGLE)
"Convert an angle from radians to arcseconds."
(deg2asec (rad2deg ANGLE)))

(defun rad2amin (ANGLE)
"Convert an angle from radians to arcminutes."
(deg2amin (rad2deg ANGLE)))

(defun yr2sec (TIME)
"Convert time from years to seconds."
(* TIME 3.15569e7))

(defun sec2yr (TIME)
"Convert time from seconds to years."
(* TIME 3.16888e-8))

(defun hr2day (TIME)
"Convert time from hours to days."
(/ TIME 24.0))

(defun day2hr (TIME)
"Convert time from days to hours."
(* TIME 24.0))

(defun linear-dist (DIST ANGLE)
"Determine the linear size of an object from a given DISTANCE and ANGLE (arcsec)"
;; 1 rad = 206265.0 asec
(/ (* DIST ANGLE) 206265.0))

;;========================================================
;;
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


;;========================================================
;; Constants obtained from Google search 25 March 2015
(defun au2m (DIST)
"Convert AU to metres."
(* DIST 149597870700.0))

(defun au2ly (DIST)
"Convert AU to light years."
(* DIST 1.58128451e-5))

(defun au2pc (DIST)
"Convert AU to parsecs."
(* DIST 4.84813681e-6))

(defun pc2au (DIST)
"Convert parsecs to AU."
(* DIST 206264.806))

(defun pc2m (DIST)
"Convert parsecs to metres."
(* DIST 3.08567758e16))

(defun pc2ly (DIST)
"Converts parsecs to light years."
(* DIST 3.26163344))

(defun ly2pc(DIST)
"Convert light years to parsecs."
(* DIST 0.306594845))

(defun ly2m(DIST)
"Convert light years to metres."
(* DIST 9.4605284e15))

(defun ly2au(DIST)
"Convert light years to AU."
(* DIST 63239.7263))
