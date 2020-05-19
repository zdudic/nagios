#!/bin/sh
#set -x
# Nagios states
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

# Variables for end
RESULT=""
EXIT_STATUS=${STATE_OK}

PROGNAME=`/bin/basename $0`
SMBCLIENT="/usr/sfw/bin/smbclient"
GREP="/usr/bin/grep"
AWK="/usr/bin/awk"

USER=smbcheck
PASS='my_passwd'
DOMAIN=mydomain

# -- function: end script with output
endscript () {
        echo ${RESULT}
        exit ${EXIT_STATUS}
}

# -- function: usage of script
usage () {
    echo "\
Nagios plugin to check if user 'smbcheck' can authenticate to MYDOMAIN

Usage:
  ${PROGNAME} -H <host>
  ${PROGNAME} --help
"
}

# -- function: HELP
help () {
    echo; usage; echo
}

# Check if there is only one argument
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
    exit ${STATE_UNKNOWN}
fi

while [ -n "$1" ] # true if first argument is non-null
do
        case $1 in
                --help | -h )
                        help
                        exit ${STATE_OK};;
                -H )
                        shift
                        HOST=$1;;
                * )
                        usage
                        exit ${STATE_UNKNOWN};;
        esac
        shift # if there is no shift, script will continue with host as null
done

OUTPUT=`${SMBCLIENT} //${HOST}/homes -c "pwd" -U ${USER}%${PASS} -W ${DOMAIN}  2>&1 |${GREP} Domain=`

if [ "$?" -eq "0" ]
then
        RESULT="OK Authentication successful on ${OUTPUT}"
        EXIT_STATUS=${STATE_OK}
else
        RESULT="Authentication failed on ${DOMAIN}: ${OUTPUT}"
        EXIT_STATUS=${STATE_CRITICAL}
fi

endscript


