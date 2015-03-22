/bin/sh

#Define global variables
REPORT_DIR=/tmp/skipfish-report
URI_TO_IGNORE=/css/,/img/,/images/,/js/,/doc/
TARGET_URL=http://mysite.com
TARGET_ROOT_URL=$TARGET_URL
INTERACTIVE_MODE=YES

#
#Clean up report directory if exists...
#
if [ -d $REPORT_DIR ];
then
 rm -rf $REPORT_DIR
fi

#
#Initialize custom dictionary if do not exists...
#
if [ ! -f dictionaries/custom-dictionnary.wl ];
then
 touch dictionaries/custom-dictionnary.wl
fi

#
#Define running mode (interactive or quiet)
#
if [ "$INTERACTIVE_MODE" = "YES" ];
then
 RUNNING_MODE=""
else
 RUNNING_MODE="-u"
fi

#
#Start scan...
#
skipfish -b i -I $TARGET_ROOT_URL -X $URI_TO_IGNORE -Z -o $REPORT_DIR -M -Q $RUNNING_MODE -S dictionaries/extensions-only.wl
-W dictionaries/custom-dictionnary.wl -Y -R 5 -G 256 -l 3 -g 10 -m 10 -f 20 -t 60 -w 60 -i 60 -s 1024000 -e $TARGET_URL
#


<<COMMENT1
Global variables description:

REPORT_DIR: Target directory in which SkipFish will generate the scan report.
URI_TO_IGNORE: Comma separated URIs list that the scan must ignore.
TARGET_URL: Target application url.
TARGET_ROOT_URL: Root url of the application (used to limit scan to the application).
INTERACTIVE_MODE: Used to indicate to SkipFish to run in interactive or quiet mode (no realtime progress stats for quiet mode).

Options used to specify authentication and access behaviors:

-b: Use headers consistent with MSIE.
The "-A" option can be used to specify authentication credentials using "login:password" format.


Options used to specify crawl scope behaviors:

-I: Only follow URLs matching url specified in $TARGET_ROOT_URL variable.
-X: Exclude URLs matching URIs specified in $URI_TO_IGNORE variable.
-Z: Do not descend into 5xx locations.

Options used to specify reporting behaviors:

-o: Write output to directory specified in $REPORT_DIR variable.
-M: Log warnings about mixed content / non-SSL passwords.
-Q: Completely suppress duplicate nodes in reports.
-u: Be quiet, disable realtime progress stats.

Options used to specify dictionary management behaviors:

Here we configure scan to learn from the application and keep informations found for the next scan of the application. We also seed learning with a dictionary containing only extension elements that the scan must use to discover files...

-S: Load a supplemental read-only wordlist, is the seeding dictionary.
-W: Use a specified read-write wordlist , is the dictionary built using the informations gathered during the scan.
-Y: Do not fuzz extensions in directory brute-force.
-R: Purge, into the dictionary built from application scan, words hit more than 5 scans ago.
-G: Maximum number of keyword guesses to keep, here we keep 256 keywords.

Options used to specify performance settings:

-l: Max requests per second, here we limit to 3.
-g: Max simultaneous TCP connections, here we limit to 10.
-m: Max simultaneous connections, per target IP, here we limit to 10.
-f: Max number of consecutive HTTP errors, here we limit to 20.
-t: Total request response timeout, here we limit to 1 minute.
-w: Individual network I/O timeout, here we limit to 1 minute.
-i: Timeout on idle HTTP connections, here we limit to 1 minute.
-s: Response size limit, here we limit to 1024 Kb.
-e: Do not keep binary responses for reporting.
COMMENT1
