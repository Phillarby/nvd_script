#!/bin/bash

# Bash script to download a snapshot of the NIST NVD JSON feeds
# gets all files from 2002 to the current year including the modified
# and recent files.  

baseurl=https://nvd.nist.gov/feeds/json/cve/1.1/
fileextensions=('.json.gz' '.meta' '.json.zip')

# Build an array of the files to download.  Assumes files are from 2002
# to the current year, with modified and recent files
thisyear=$(date +%Y)
files=($(seq 2002 1 $thisyear))
files+=('modified' 'recent')

# Download the files onto the current folder
for file in ${files[@]}
do
  for extension in ${fileextensions[@]}
  do
    wget --no-check-certificate https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-$file$extension -O ./nvdcve-1.1-$file$extension
  done
done
