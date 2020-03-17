#!/bin/bash

# Upload NIST nvd files from the current folder into nexus.  Checks if the files
# are new before uploading by verifying the sha256 hash in the the local .meta file
# against the remote .meta file
#
# Usage: ./upload.sh [nexus username] [nexus password]
# Parameter: [nexus username] mandatory - a nexus account with permission to push to the NVD repository
# Parameter: [nexus password] mandatory - the password for the nexus account

# Define static parameters
nexusrepo='http://localhost:8081/repository/nvd/'
fileextensions=('.json.gz' '.meta' '.json.zip')
logfile='/Users/phil.larby-cic-uk@uk.ibm.com/nvduploader.log'

exitcode=0

# log function outputs to standard out and specified log file
log ()
{
    eval echo [$(date)]$'\t'[$1]$'\t'$2 | tee -a $logfile
}

# create the log file if it does not exist
if [ ! -e '$logfile' ]; then
    touch '$logfile'
fi

log 'INFO' 'Starting NVD upload'

if [ -z "$2" ]
then  
  log 'WARN' 'Mandatory parameters not specified.  Upload aborting'
else	
  nexususer=$1
  nexuspass=$2

  # get meta files in the current folder as an array
  files=($(ls *.meta))
  log 'INFO' '${#files[@]} NVD files found'

  for file in ${files[@]}
  do
    # get the base filename
    basefile=$(basename $file .meta)

    # get the sha256 fingerprint of the local file from metadata 
    localhash=$(grep sha256 $file | cut -d ':' -f 2)
    if [ -z $localhash ]; then 
      localhash='local'
    fi

    # get the sha256 fingerprint of the remote file from metadata 
    remotehash=$(curl -s $nexusrepo$file | grep sha256 | cut -d ':' -f 2)
    if [ -z $remotehash ]; then 
      remotehash='remote'
    fi

    # upload any files where the hash of the local copy does not match the remote copy
    if [ $localhash != $remotehash ]; then
      # upload al variations of file extensions
      for extension in ${fileextensions[@]}
      do
        # simple put to nexus repo to update files - supported for RAW, MAVEN 2 and YUM format repos 
        log 'INFO' 'updating $basefile$extension'
        httpstatus=$(curl -s -w "%{http_code}" -u $nexususer:$nexuspass --upload-file $basefile$extension $nexusrepo$basefile$extension)
        if [[ $httpstatus -eq 201 ]]; then
          log 'INFO' 'updating $basefile$extension completed with http status $httpstatus'
        else
          log 'ERROR' 'updating $basefile$extension failed with http status $httpstatus'
          exitcode=1
        fi
      done
    else
      log 'INFO' '$basefile does not need updating'
    fi

  done	
fi

if [[ $exitcode -eq 0 ]]; then 
  log 'INFO' 'completed successfully'
else 
  log 'WARN' 'completed with errors'
fi

exit $exitcode
