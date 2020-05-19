#!/usr/bin/sh
#set -x

# Nagios plugin : determine ambient temperature around a server
# -- supported systems
# Sun Enterprise T5240 and SunFire X4200/X4500

# Nagios plugin return values
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

# variables
WARNTEMP=$2
CRITTEMP=$3
ILOMUSER=admin
PASSWDFILE=/opt/csw/libexec/nagios-plugins/ipmitool/.passwd.alom

# Function : error and exit 1
err() {
        echo "\n ERROR: $* \n"
        exit 1
}

# check if arguments are provided (hostname, warning, critical temperature)
if [ $# != 3 ]
then
        echo ; echo "USAGE : `basename $0` hostname warn_tmp(C) crit_tmp(C)" ; echo
        exit 2
fi

# check if critical temp is higher than warning
if [ $2 -ge $3 ]
then
        echo NOTE : Critical temperature must be higher than warning temperature.
        exit 3
fi


# Function: end script with output, with performance data for NagiosGraph
endscript () {
        echo "${RESULT} | PerfData=${TEMP};${WARNTEMP};${CRITTEMP}"
        exit ${EXIT_STATUS}
}

# find if ilom name has -alom or .alom (hostname-alom or hostname.alom)
ILOMNAME=`host $1.alom > /dev/null`
if [ $? -eq 0 ]
then
        ILOMNAME=$1.alom
else
        ILOMNAME=$1-alom
fi

PNAME=`ipmitool -H ${ILOMNAME} -U ${ILOMUSER} -f ${PASSWDFILE} fru | head | grep "Product Name" \
        | nawk -F":" '{print $2}' | nawk '{print $1}'` \
        || err "Cannot find what system type is $1"

case ${PNAME} in
T5240)
        TEMP=`ipmitool -H ${ILOMNAME} -U ${ILOMUSER} -f ${PASSWDFILE} sdr type temperature \
        | grep T_AMB \
        | awk -F"|" '{print $5}' | awk '{print $1}'`
        #
        if [ ${TEMP} -le ${WARNTEMP} ]
        then
                RESULT="Host: $1 : Ambient Temp(C): ${TEMP} : OK"
                EXIT_STATUS=${STATE_OK}
        elif [ ${TEMP} -gt ${WARNTEMP} ] && [ ${TEMP} -le ${CRITTEMP} ]
        then
                RESULT="Host: $1 : Ambient Temp(C): ${TEMP} : WARNING"
                EXIT_STATUS=${STATE_WARNING}
        else
                RESULT="Host: $1 : Ambient Temp(C): ${TEMP} : CRITICAL"
                EXIT_STATUS=${STATE_CRITICAL}
        fi
        #
        ;;

ILOM)
        # can be X4500 or X4200

        BOARD=`ipmitool -H ${ILOMNAME} -U ${ILOMUSER} -f ${PASSWDFILE} fru | head | grep "Board Product" \
        | nawk -F"ASSY,SERV PROCESSOR," '{print $2}' | nawk '{print $1}'` \
        || err "Cannot find whar Board Product is."

        if [ ${BOARD} = "G1/2" ]
        then
                #  X4200
                TEMP=`ipmitool -H ${ILOMNAME} -U ${ILOMUSER} -f ${PASSWDFILE} sdr type temperature \
                | grep fp.t_amb \
                | nawk -F"|" '{print $5}' | nawk '{print $1}'`

        elif [ ${BOARD} = "X4500" ]
        then
                # X4500
                TEMP=`ipmitool -H ${ILOMNAME} -U ${ILOMUSER} -f ${PASSWDFILE} sdr type temperature \
                | grep dbp.t_amb \
                | nawk -F"|" '{print $5}' | nawk '{print $1}'`
        fi

        # --

        if [ ${TEMP} -le ${WARNTEMP} ]
        then
                RESULT="Host: $1 : Ambient Temp(C): ${TEMP} : OK"
                EXIT_STATUS=${STATE_OK}
        elif [ ${TEMP} -gt ${WARNTEMP} ] && [ ${TEMP} -le ${CRITTEMP} ]
        then
                RESULT="Host: $1 : Ambient Temp(C): ${TEMP} : WARNING"
                EXIT_STATUS=${STATE_WARNING}
        else
                RESULT="Host: $1 : Ambient Temp(C): ${TEMP} : CRITICAL"
                EXIT_STATUS=${STATE_CRITICAL}
        fi

        ;;
esac

# provide output and nagios return value
endscript

