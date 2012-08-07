#
# PortalInfo.sh
#  
# (it is not necessary to add  #!/bin/sh at the top of this script)
#
# This file contains environment variables and function declarations
# that could be used by the pilot script to manages the application
# execution while it runs on the distrubuted infrastructure
#
# Author: Riccardo Bruno (riccardo.bruno@ct.infn.it)

echo "--------------------------------"
echo "Executing portal info script ..."
echo "--------------------------------"


##
## Functions to manage the Science Gateway Job Perusal (SGJP)
##

# Start job perusal 
start_perusal()
{
  curl $SG_PORTAL_SGJP_SERVER:$SG_PORTAL_SGJP_PORT/sgjp 2>/dev/null > sgjp_client.py && python sgjp_client.py 2 "${SG_PORTAL_SCREEN_NAME}" "${SG_PORTAL_JOB_DESC}" 2>sgjp.log >sgjp.log &
  SGJP_PID=$!
}

# Stop job perusal
#
stop_perusal()
{
  kill $SGJP_PID && wait $SGJP_PID 2>/dev/nul
}

##
## Functions to manage the start/stop user notification
##


# Sends the start notification email
job_notify_start()
{
  if [ "true" = $(echo $SG_PORTAL_JOB_NOTIFY_START | awk '{ print tolower($1) }') ]
  then
    echo "User selected job start notification ..."
    # prepare the mail body
    job_notify_template start
    # get the notifier client
    if [ -z $SG_PORTAL_APP_NOTIFIER ]; then
      SG_PORTAL_APP_NOTIFIER=$(mktemp)
      curl http://$SG_PORTAL_SGJP_SERVER:$SG_PORTAL_SGJP_PORT/notifier 2>/dev/null > $SG_PORTAL_APP_NOTIFIER
    fi
    # call notifier
    SG_PORTAL_JOB_NOTIFY_SUBJ="Start notification for job: ${SG_PORTAL_JOB_DESC}"
    python $SG_PORTAL_APP_NOTIFIER $SG_PORTAL_SGJP_SERVER $SG_PORTAL_SGJP_PORT $SG_PORTAL_NAME@noreply $SG_PORTAL_JOB_NOTIFY_EMAIL "${SG_PORTAL_JOB_NOTIFY_SUBJ}" $SG_PORTAL_APP_NOTIFY_TEMPLATE AppLogo.png
    # remove template    
    rm -f $SG_PORTAL_APP_NOTIFY_TEMPLATE
  fi
}

# Sends the stop notification email
job_notify_stop()
{
  if [ "true" = $(echo $SG_PORTAL_JOB_NOTIFY_STOP  | awk '{ print tolower($1) }') ]
  then
    echo "User selected job stop notification ..."
    # prepare the mail body
    job_notify_template stop
    # get the notifier client
    if [ -z $SG_PORTAL_APP_NOTIFIER ]; then
      SG_PORTAL_APP_NOTIFIER=$(mktemp)
      curl http://$SG_PORTAL_SGJP_SERVER:$SG_PORTAL_SGJP_PORT/notifier 2>/dev/null > $SG_PORTAL_APP_NOTIFIER
    fi
    # call notifier
    SG_PORTAL_JOB_NOTIFY_SUBJ="Stop notification for job: ${SG_PORTAL_JOB_DESC}"
    python $SG_PORTAL_APP_NOTIFIER $SG_PORTAL_SGJP_SERVER $SG_PORTAL_SGJP_PORT $SG_PORTAL_NAME@noreply $SG_PORTAL_JOB_NOTIFY_EMAIL "${SG_PORTAL_JOB_NOTIFY_SUBJ}" $SG_PORTAL_APP_NOTIFY_TEMPLATE AppLogo.png
    rm -f $SG_PORTAL_APP_NOTIFY_TEMPLATE
  fi
}

# Edit this funtion in order to have a different notification template
# $1 - start/stop; distinguish between notification types
# The template will be placed into the SG_PORTAL_APP_NOTIFY_TEMPLATE 
# variable
job_notify_template()
{
  if [ "start" = "${1}" ]; then
    SG_PORTAL_APP_NOTIFY_MODE="<i>The job submission identified by '${SG_PORTAL_JOB_DESC}' started at: ${STARTTS}</i><br/><br/>"
  fi
  if [ "stop"  = "${1}" ]; then
    SG_PORTAL_APP_NOTIFY_MODE="<i>The job submission identified by '${SG_PORTAL_JOB_DESC}' finished at: ${ENDTS}</i><br/><br/>"
  fi
  SG_PORTAL_APP_NOTIFY_TEMPLATE=$(mktemp)

  cat > $SG_PORTAL_APP_NOTIFY_TEMPLATE <<EOF
<H4>Science Gateway Notification</H4><hr><br/>
<p><img src="cid:image1">
<b>Description:</b> Notification for the application <b>${SG_PORTAL_APP_NAME}</b><br/><br/>
${SG_PORTAL_APP_NOTIFY_MODE}
<b>Disclaimer:</b><br/>
<i>This is an automatic message sent by the ${SG_PORTAL_NAME} Science Gateway<br/>
If you did not submit any jobs through the Science Gateway, please
<a href=\"mailto:credentials-admin@ct.infn.it\">contact us</a></i><br/>
EOF
}

##
## Functions to manage the Science Gateway LFC file system service (SGFS)
##

# Verify if application and user are stored into the
# Grid file catalog and insert them in case the application
# or the user is not identified
#
# $1 - Catalog hostname
# $2 - TopBDII
#
sgfs_check_app_user()
{
  PREV_LFC_HOST=$LFC_HOST
  PREV_LCG_GFAL_INFOSYS=$LCG_GFAL_INFOSYS  
  export LFC_HOST=$1
  export LCG_GFAL_INFOSYS=$2
  lfc-ls /grid/$VO_NAME/sgfs/$SG_PORTAL_APP_NAME/$SG_PORTAL_SCREEN_NAME
  RES=$?
  if [ $RES -ne 0 ]
  then
      lfc-mkdir -p /grid/$VO_NAME/sgfs/$SG_PORTAL_APP_NAME/$SG_PORTAL_SCREEN_NAME
      RES=$?
      if [ $RES -ne 0 ]
      then
          echo "SGFS: Unable to create directory: /grid/$VO_NAME/sgfs/$SG_PORTAL_APP_NAME/$SG_PORTAL_SCREEN_NAME" >&2
      fi
  else
      #APP/USER exists
      echo "SGFS: Application and user already registered"
  fi
  export LFC_HOST=$PREV_LFC_HOST
  export LCG_GFAL_INFOSYS=$PREV_LCG_GFAL_INFOSYS
}

# Save a given file to a random Grid storage element
#
# $1 - Catalog hostname
# $2 - TopBDII
# $3 - FileName
#
sgfs_save_rnd_lfc()
{
  SGFS_RND_SE_HOST=
  SGFS_LIST_SE=$(mktemp)
  lcg-infosites --vo $VO_NAME se -v 1 > $SGFS_LIST_SE
  SGFS_NCES=$(cat $SGFS_LIST_SE | wc -l) 
  if [ $SGFS_NCES -gt 0 ]; then
     SGFS_RNDCE=$((1+(RANDOM%SGFS_NCES)))
     SGFS_RND_SE_HOST=$(cat $SGFS_LIST_SE | tail -n $SGFS_RNDCE | head -n 1)
  fi
  rm -f $SGFS_LIST_SE
  if [ "${SGFS_RND_SE_HOST}" = "" ]; then 
    echo "SGFS Warning: Unable to get a random CE an attempt with the default SE will be done" >&2 
  fi
  # Save the file ...  
  sgfs_save_lfc $1 $2 $SGFS_RND_SE_HOST $3
}

# Save a given file to a specified Grid storage element
#
# $1 - Catalog hostname
# $2 - TopBDII
# $3 - SE_HOST
# $4 - FileName
#
sgfs_save_lfc()
{
  sgfs_check_app_user $1 $2
  if [ $RES -eq 0 ]
  then
      # Save original LFC_HOST/LCG_GFAL_INFOSYS values
      PREV_LFC_HOST=$LFC_HOST
      PREV_LCG_GFAL_INFOSYS=$LCG_GFAL_INFOSYS  
      export LFC_HOST=$1
      export LCG_GFAL_INFOSYS=$2
      SGFS_SE_HOST=$3
      SGFS_FILE_NAME=$4
      SGFS_PREFIX=$(date +'%Y%m%d%H%M%S')"_"$(echo $$)"_"
      SGFS_LFN_PATH="/grid/$VO_NAME/sgfs/$SG_PORTAL_APP_NAME/$SG_PORTAL_SCREEN_NAME/${PREFIX}$SGFS_FILE_NAME"
      SGFS_LFN_NAME="lfn:"$SGFS_LFN_PATH
      # If no SE is specified the command will try the default SE
      if [ "${SGFS_SE_HOST}" = "" ]
      then
          SGFS_SE_HOST_OPT=""
      else
          SGFS_SE_HOST_OPT="-d $SGFS_SE_HOST"
      fi
      # Make an archive containing the output
      echo "SGFS_LFC_HOST        : "$LFC_HOST
      echo "SGFS_LCG_GFAL_INFOSYS: "$LCG_GFAL_INFOSYS
      echo "SGFS_SE_HOST         : "$SE_HOST
      echo "SGFS_LFN             : "$LFN_NAME      
      lcg-cr --vo $VO_NAME -n 2 file:$3 $SGFS_SE_HOST_OPT -l $SGFS_LFN_NAME
      RES=$?
      # Include file storage metadata remark
      if [ $RES -eq 0 ]
      then
          lfc-setcomment $SGFS_LFN_PATH "${SG_PORTAL_JOB_DESC}"      
      else
          echo "SGFS: Unable to store file $3 on the Grid" >&2
      fi
      # Restore previous LFC_HOST/LCG_GFAL_INFOSYS values
      export LFC_HOST=$PREV_LFC_HOST
      export LCG_GFAL_INFOSYS=$PREV_LCG_GFAL_INFOSYS
  fi 
}

##
## Other customized user' functions and assignments ...
##

