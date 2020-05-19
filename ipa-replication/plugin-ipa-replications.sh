#!/usr/bin/env bash

# please feel free to edit and improve, thanks
#---------------------------------------------------

# Nagios plugin return values
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

# end script with output
endscript () {
        echo "${RESULT}"
        exit ${EXIT_STATUS}
}

# check if server is IPA
systemctl status -l ipa.service > /dev/null
if [ $? -ne 0 ]; then
 RESULT="I am not IPA server" ; EXIT_STATUS=3
 endscript
fi

thisserver=`hostname`

# IPA Directory manager's password is encrypted
# this is how it's decrypted
ipa_passwd="enter_directory_manager_password"

# get servers that participate in replication
listservers=`/sbin/ipa-replica-manage -p ${ipa_passwd} \
            list -v ${thisserver} | grep replica | awk -F: '{print $1}'` > /dev/null

replicastatus=`/sbin/ipa-replica-manage -p ${ipa_passwd} \
              list -v ${thisserver} | grep "last update status" | awk -F\( '{print $2}' | awk -F\) '{print $1}'` > /dev/null

listserversarray=(${listservers})
server_index=${!listserversarray[*]} #; echo ${server_index}
replicastatusarray=(${replicastatus})
replica_status_index=${!replicastatusarray[*]} #; echo ${replica_status_index}


# initial replica status is okay
total_status=OKAY

# for each server, check its status, if some is not zero, then total is not okay
for i in ${server_index}
do
  if [ ${replicastatusarray[${i}]} -ne 0 ]; then
     total_status=NOT_OKAY
  fi
done
#
# now assign values to RESULT and EXIT_STATUS
if [ ${total_status} = OKAY ]; then
      RESULT=`echo -n "Replica status: "
         for i in ${server_index}
         do
           echo -n " ${listserversarray[${i}]} (${replicastatusarray[${i}]}) "
         done
      `
      EXIT_STATUS=${STATE_OK}
else
      RESULT=`echo -n "Replica status: "
         for i in ${server_index}
         do
           echo -n " ${listserversarray[${i}]} (${replicastatusarray[${i}]}) "
         done
      `
      EXIT_STATUS=${STATE_WARNING}
fi

endscript


