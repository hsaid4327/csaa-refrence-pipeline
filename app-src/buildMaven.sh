#!/bin/bash
  
 pomFile="pom.xml"

  if [[ ! -a $pomFile ]]; 
    then
  echo "The file does not exist"
  echo "$0: must be run from the root directory of the application"
   exit 1
  fi 
 
 if [[ $# -lt 1 ]];
   then
 echo "The version number for the build must be provided. $0 version [example: $0 1.1]"
 exit 1
 fi
 version=$1

 mvn versions:set -DnewVersion=$version
 mvn clean install
 mvn versions:commit
