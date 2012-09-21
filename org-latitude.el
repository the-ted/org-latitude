;; This file starts a process that checks your location on google latitude,
;; and notifies you of any Todo items tagged with that location.

;; google curl 'http://www.google.com/latitude/apps/badge/api?user=XXXXXXXXXXXX&type=atom'

(defvar lat/googleurl "http://www.google.com/latitude/apps/badge/api?user="
  "The google URL that will return your location"
)
(defvar lat/userid "EDITME"
  "Your Google User ID"
)
(defvar lat/email "EDITME"
  "The email address to send the formatted agenda"
)
(defvar lat/current-location [0 0]
  "This variable holds your current location"
)

(defvar lat/storedlocations '(("home" . [38.007 -122.273])
                            ("work" . [37.498 -122.376])
  "This variable holds the coordinates of your stored locations"
)

(defvar lat/matchingTODO "Todo"
  "This variable holds the TODO-query that is passed to the agenda command"
)


(defun lat/graburl (userid)
   "grab your current location from your google latitude url"
   (message "Grabbing URL")
   (shell-command-to-string (format "curl '%s'" (concat lat/googleurl userid "&type=atom")))
)

(defun lat/currentloc (userid)
  "Get the current location of the user identifier given by userid"
  (interactive)
  (let ((result (lat/graburl userid)))
    (string-match "\\([-0-9]*\\.[0-9]*\\) \\([-0-9]*\\.[0-9]*\\)" result)
    (vector (string-to-number (match-string 1 result)) (string-to-number (match-string 2 result)))
  )
)

(defun lat/interval (userid)
  "Get the range of the location estimate"
  (interactive)
  (let ((result (lat/graburl userid)))
    (string-match "<georss:radius>\\([0-9]*\\)</georss:radius>" result)
    (string-to-number (match-string 1 result))
  )
)

(defvar lat/current-margin (lat/interval lat/userid)
   "This variable holds the current margin-of-error"
)

(defun lat/convert_radians (number)
  "Convert a number from degress to radians"
  (/ (* pi number) 180.0))

;; Get the distance between two coordinates via Equirectangular approximation:
;; http://www.movable-type.co.uk/scripts/latlong.html
(defun lat/equidist (locvec1 locvec2)
  "calculate the distance between two lat/long pairs in kilometers"
  (let* ( (lat1 (lat/convert_radians (aref locvec1 0)))
	 (lon1  (lat/convert_radians (aref locvec1 1)))
	 (lat2  (lat/convert_radians (aref locvec2 0)))
	 (lon2  (lat/convert_radians (aref locvec2 1)))
	 (x (* (cos (/ (+ lat1 lat2) 2)) (- lon2 lon1)))
	 (y (- lat2 lat1))
	 )
    (* 6371000 (sqrt (+ (* x x) (* y y))))
    )
)



(defun lat/difflocation (location1 location2 margin)
  "Test if two locations are different"
  (> (lat/equidist location1 location2) margin)
)

(defun lat/matchinglocations ()
  "Test the distance between the current location and 
   all of the locations in lat/storedlocations, and return a list
   that will match all of the ones that are equal to the current location"
   (mapconcat (lambda (element)
	     (let ((name (car element))
		   (location (cdr element)))
	          (if (not (lat/difflocation lat/current-location location lat/current-margin))
		      name)))
	     lat/storedlocations "+")
)

(defun lat/makeagenda ()
  "Make the agenda corresponding to all of the locations that have changed"
  (let ((locations (concat (lat/matchinglocations) "/" lat/matchingTODO)))
    (org-add-agenda-custom-command
     '("X" tags (eval locations)))
    (org-batch-agenda "X")
    )
)


(defun lat/testcurrent ()
  "Test to see if the current location is different than the existing location. If it is,
   update the current location, current margin of error, and make the agenda for all the
   locations that match."
  (let ((online_location (lat/currentloc lat/userid))
	(online_margin   (lat/interval lat/userid))
	result)
  (if (lat/difflocation lat/current-location online_location online_margin)
      (progn
	(message "Updating current location...")
	(setq lat/current-location online_location)
	(setq lat/current-margin online_margin)
	(setq result (substring-no-properties (lat/makeagenda)))
	(kill-buffer)
	)
    )
  result
  )
)

(defun lat/mail (string)
  "Send a mail message"
	 (compose-mail lat/email "RELEVANT AGENDA")
	 (insert string)
	 (funcall send-mail-function)
	 (flet ((yes-or-no-p (prompt) t))
   (kill-buffer))
)

(defvar lat/timer nil)

(defun lat/timer-callback ()
  (let ((result (lat/testcurrent)))
    (if result
	(lat/mail result)
      )
    )
)

;; start functions
(defun lat/timer-run-once ()
  (interactive)
  (when (timerp lat/timer)
    (cancel-timer lat/timer))
    (setq lat/timer
          (run-with-timer 1 nil 'lat/timer-callback)))

(defun lat/timer-start ()
  (interactive)
  (when (timerp lat/timer)
    (cancel-timer lat/timer))
  (setq lat/timer
          (run-with-timer 15 15 'lat/timer-callback)))

;; stop function
(defun lat/timer-stop ()
  (interactive)
  (when (timerp lat/timer)
    (cancel-timer lat/timer))
  (setq lat/timer nil))

;; (setq lat/current-location [0 0])
;; (lat/timer-run-once)
;; (lat/timer-start)
;; (lat/timer-stop)
