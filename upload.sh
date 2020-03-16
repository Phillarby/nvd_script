#!/bin/bash

# Upload NIST nvd files from the current folder into nexus.  Checks if the files
# are new before uploading by verifying the sha256 hash in the the .meta file

nexusrepo='http://localhost:8081/repository/nvd/'
fileextensions=('.json.gz' '.meta' '.json.zip')

if [ -z "$" ]
then  
  echo "Usage: ./upload.sh [nexus username] [nexus password]"
else	
  nexususer=$1
  nexuspass=$2

  # get meta files in the current folder as an array
  files=($(ls *.meta))
  for file in ${files[@]}
  do
    # get the base filename
    basefile=$(basename $file .meta)
    echo basefile : $basefile

    # get the sha256 fingerprint of the local file from metadata 
    localhash=$(grep sha256 $file | cut -d ':' -f 2)
    if [ -z $localhash ]; then 
      localhash='local'
    fi
    echo local file hash: $localhash

    # get the sha256 fingerprint of the remote file from metadata 
    remotehash=$(curl -s $nexusrepo$file | grep sha256 | cut -d ':' -f 2)
    if [ -z $remotehash ]; then 
      remotehash='remote'
    fi
    echo remote file hash: $remotehash

    # upload any files where the hash of the local copy does not match the remote copy
    if [ $localhash != $remotehash ]; then
      # upload al variations of file extensions
      for extension in ${fileextensions[@]}
      do
        # simple put to nexus repo to update files - supported for RAW, MAVEN 2 and YUM format repos 
        curl -v -u $nexususer:$nexuspass --upload-file $basefile$extension $nexusrepo$basefile$extension
      done
    else
      echo $basefile does not need updating
    fi

  done	
fi
