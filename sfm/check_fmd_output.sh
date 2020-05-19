#!/usr/bin/sh
#set -x
# please feel free to edit and improve, thanks
# ---------------------------------------

# Nagios plugin return values
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

FMADM=/usr/sbin/fmadm
AWK=/usr/bin/awk
SUDO=/opt/csw/bin/sudo

# Function: end script with output
endscript () {
        echo ${RESULT}
        exit ${EXIT_STATUS}
}

# Check if fmdump exists
if [ ! -f ${FMADM} ]
then
        RESULT="Cannot find ${FMADM}"
        EXIT_STATUS=${STATE_WARNING}
        endscript
fi

# check if service 'fmd' is enabled
if [ `svcs -H fmd | awk '{print $1}'` != online ]
then
        RESULT="The fmd service is not online!"
        EXIT_STATUS=${STATE_WARNING}
        endscript
fi

# Run fmdump
# -r = Show Fault Management Resource with their Identifier (FMRI) and state
UUID=`${SUDO} ${FMADM} faulty -r | ${AWK} '$0 !~ /TIME/ && $0 !~ /STATE/ && $0 !~ /^----/ {print $0}'`

if [ -n "${UUID}" ]
then
        RESULT="${UUID}"
        EXIT_STATUS=${STATE_CRITICAL}
else
        RESULT="The Fault Manager does not report any hardware problem."
        EXIT_STATUS=${STATE_OK}
fi

endscript

