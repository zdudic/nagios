#!/bin/ksh
# Nagios plugin return values
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

# hard coded warning/crit in F
# 20C=68F 22C=72F 24C=75F 26C=79F 28C=82F 30C=86F 32C=89F 34C=93F
# 36C=97F 38C=100F 40C=104F
temp_warn=90
temp_crit=100

# --- END SCRIPT WITH OUTPUT
endscript () {
        echo "${RESULT}"
        exit ${EXIT_STATUS}
}

usage() {
        RESULT="$0 "
        EXIT_STATUS="${STATE_UNKNOWN}"
        endscript
}

# DAQ hostname
temp_module=$1

# check if there is at least one argument
if [ $# -ne 1 ]; then
        usage
fi

temp_f=`curl --silent http://${temp_module}/state.xml | grep sensor1temp | awk -F \> '{print $2}' | awk -F \< '{print $1}'`

# check if result is null
if [ -z ${temp_f} ]; then
        RESULT="Cannot get temperature for ${temp_module}"
        EXIT_STATUS="${STATE_UNKNOWN}"
fi

if [ ${temp_f} -gt ${temp_crit} ]; then
        RESULT="CRITICAL ${temp_f}F for ${temp_module} | Temp=${temp_f};${temp_warn};${temp_crit}"
        EXIT_STATUS="${STATE_CRITICAL}"
elif [ ${temp_f} -lt ${temp_warn} ]; then
        RESULT="OK ${temp_f}F for ${temp_module} | Temp=${temp_f};${temp_warn};${temp_crit}"
        EXIT_STATUS="${STATE_OK}"
else
        RESULT="WARNING ${temp_f}F for ${temp_module} | Temp=${temp_f};${temp_warn};${temp_crit}"
        EXIT_STATUS="${STATE_WARNING}"
fi

# finish the script
endscript

