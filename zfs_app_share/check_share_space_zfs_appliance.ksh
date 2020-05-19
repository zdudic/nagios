#!/bin/ksh
# -----------------------------------------------------------------
# 4-7-2017 : zd: Add support for a pool
# 4-11-2017 : zd: Add support for a snapshot
# -----------------------------------------------------------------

PROGNAME=`/bin/basename $0`

# ------ Nagios plugin return values
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

# usage function
usage() {
echo " \
Usage
        ${PROGNAME} <zfsapp> <pool> <project> <share> <war_free_%> <crit_free_%>
"
}

# End script with output, with performance data for pnp4nagios
endscript () {
        echo ${RESULT}
        exit ${EXIT_STATUS}
}

# check if there are 6 arguments
if [ $# != 6 ]; then
        usage ; exit 3
fi

# temp file and cleanup of same
tmp_file=/tmp/${PROGNAME}.tmp

# --- CLEANING SUBROUTINE
tmp_file_cleaning () {
        [ -f ${tmp_file}.$$ ] && rm ${tmp_file}.$$
}

# --- cleaning in case of script termination and regular exit
trap tmp_file_cleaning HUP INT QUIT ABRT EXIT

ssh -i /var/log/nagios/.ssh/id_rsa nagios@$1 <<EOF > ${tmp_file}.$$
shares
set pool=$2
select $3
select $4
show
EOF

# Calculation is done in Mega

# Get quota
share_quota=`grep "quota =" ${tmp_file}.$$ | awk '{print $3}'`
if [ ${share_quota: -1} = G ]; then
  share_quota=`(echo "scale=2; ${share_quota%?}*1024" | bc -l)`
elif [ ${share_quota: -1} = T ]; then
  share_quota=`(echo "scale=2; ${share_quota%?}*1024*1024" | bc -l)`
else
  share_quota=`echo ${share_quota%?}`
fi

# Get available space
share_space_available=`grep "space_available" ${tmp_file}.$$ | awk '{print $3}'`
if [ ${share_space_available: -1} = G ]; then
  share_space_available=`(echo "scale=2; ${share_space_available%?}*1024" | bc -l)`
elif [ ${share_space_available: -1} = T ]; then
  share_space_available=`(echo "scale=2; ${share_space_available%?}*1024*1024" | bc -l)`
else
  share_space_available=`echo ${share_space_available%?}`
fi

# Get space used by data
share_space_data=`grep "space_data" ${tmp_file}.$$ | awk '{print $3}'`
if [ ${share_space_data: -1} = G ]; then
  share_space_data=`(echo "scale=2; ${share_space_data%?}*1024" | bc -l)`
elif [ ${share_space_data: -1} = T ]; then
  share_space_data=`(echo "scale=2; ${share_space_data%?}*1024*1024" | bc -l)`
else
  share_space_data=`echo ${share_space_data%?}`
fi

# Get space used by snapshots
share_space_snapshots=`grep "space_snapshots" ${tmp_file}.$$ | awk '{print $3}'`
if [ ${share_space_snapshots} = 0 ]; then
  share_space_snapshots=0
elif [ ${share_space_snapshots: -1} = G ]; then
  share_space_snapshots=`(echo "scale=2; ${share_space_snapshots%?}*1024" | bc -l)`
elif [ ${share_space_snapshots: -1} = T ]; then
  share_space_snapshots=`(echo "scale=2; ${share_space_snapshots%?}*1024*1024" | bc -l)`
else
  share_space_snapshots=`echo ${share_space_snapshots%?}`
fi

# Total space is space used by data and snapshots
share_space_total=`(echo "scale=2; ${share_space_data}+${share_space_snapshots}" | bc -l)`

# warn and crit arguments are in %
WARNING=$5
CRITICAL=$6
# Warning size is $warn_size_free
# Critical size is $crit_size_free
warn_used=`(echo "scale=2; (100-${WARNING})*${share_quota}/100" | bc -l)`
warn_free=`(echo "scale=2; ${WARNING}*${share_quota}/100" | bc -l)`
crit_used=`(echo "scale=2; (100-${CRITICAL})*${share_quota}/100" | bc -l)`
crit_free=`(echo "scale=2; ${CRITICAL}*${share_quota}/100" | bc -l)`

if [ ${share_space_available} -gt ${warn_free} ]
then
  RESULT="$2/$3/$4 OK - Free space ${share_space_available}MB | $2/$3/$4=${share_space_total}MB;${warn_used};${crit_used};0;${share_quota}"
  EXIT_STATUS=${STATE_OK}
elif [ ${share_space_available} -le ${warn_free} ] && [ ${share_space_available} -gt ${crit_free} ]
then
  RESULT="$2/$3/$4 WARNING - Free space ${share_space_available}MB | $2/$3/$4=${share_space_total}MB;${warn_used};${crit_used};0;${share_quota}"
  EXIT_STATUS=${STATE_WARNING}
else
  RESULT="$2/$3/$4 CRITICAL - Free space ${share_space_available}MB | $2/$3/$4=${share_space_total}MB;${warn_used};${crit_used};0;${share_quota}"
  EXIT_STATUS=${STATE_CRITICAL}
fi

# ------- provide output and nagios return value
endscript


