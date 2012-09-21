org-latitude
============

Add some location-based notifications to org-mode.

latitude scrapes your current location based off of your google
latitude location. If, within the margin of error given by latitude,
you have moved into an area, the program sends you an email with all of the 
todo-items tagged with that location.

Requires curl to scrape the data.

This is my first-ever elisp project, so don't expect anything special.

To figure out your google user id, go to:
https://latitude.google.com/latitude/b/0/apps/. The userid will be the third
line, after user=

To use org-latitude, add the .el file to your load path and put something 
like the following in your .emacs:

(require 'org-latitude)

(setq lat/userid "---Insert USERID here---")

(setq lat/email "---Insert where you want the notification emails sent----")

(setq lat/matchingTODO "TODO")

To add more locations to be searched for, change the lat/storedlocations variable.