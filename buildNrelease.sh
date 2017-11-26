#!/bin/bash

####### Workspace Cleaning #####
#rm -rf ${WORKSPACE}/*
####### Workspace Cleaning #####

set_debug() {
 if [[ ${debug_mode} == "true" ]]; then
    set -x
 fi
}



var_validation() {

 if [[ -z ${aws_access_key_id} ]] || [[ -z ${aws_secret_access_key} ]]; then
  echo "ERROR: Input parameters missing"
  exit 1
 fi

}

pomversion_update() {

  VERSION=$(cat pom.xml | egrep "SNAPSHOT" | cut -d">" -f2 | cut -d"<" -f1 | sed 's/ //g')
  VERSION1=$(echo $VERSION | cut -d"." -f1)
  VERSION2=$(echo $VERSION | cut -d"." -f2 | awk -F"-" '{print $1}')
  VERSION3="SNAPSHOT"
  VERSION2_NEW=$((${VERSION2}+1))
  VERSION_NEW=${VERSION1}.${VERSION2_NEW}-${VERSION3}

  sed -i -e "s/${VERSION}/${VERSION_NEW}/" pom.xml

}

github_checkin() {

  git checkout ${GITHUB_BRANCH}
  git pull 
  git add -A
  git commit -m "Updating version in pom.xml"
  git push https://${github_username}:${github_password}@https://github.com/saadiakhanam/java-maven-junit-helloworld.git refs/heads/${GITHUB_BRANCH}:refs/heads/${GITHUB_BRANCH}

}

build_project() {

  REPONAME=${1}
  git clone ${REPONAME}
  
  cd ./${TARGET_DIR}
  
  if [[ ! -f ./pom.xml ]]; then
    echo "ERROR: POM not found"
    exit 1
  fi

  pomversion_update()
  github_checkin()
  
  
  mvn clean
  
  mvn package
  
 
  ARTIFACT_TYPE=$(cat pom.xml | grep "packaging" | cut -d">" -f2 | cut -d"<" -f1)
  
  #ls -ltr ./target
  
  if [[ ! -d ./target ]]; then 
  echo "ERROR: target folder not found!"
  exit 1
  fi
  
  cd ./target
  
  ARTYPE=$(ls -1 | grep ".${ARTIFACT_TYPE}")
  
  if [[ -z ${ARTYPE} ]]; then
  
    echo  "ERROR: No Artifact described!"
    exit 1
  fi  
  
  if [[ ! -f ./${ARTYPE} ]]; then
    echo "ERROR: ${ARTIFACT_TYPE} not found"
    exit 1
  fi

}

s3_upload() {

S3_BUCKET=${1}
aws --region=us-east-1 s3 cp ${ARTYPE} s3://${S3_BUCKET}/

}

###### Jobs Global Variables ########
export JAVA_HOME="/opt/runtime/jdk/jdk1.8.0_151"
export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
git config --local user.name saadiakhanam
git config --local user.email saadia.khanam@aol.com
WORKSPACE=$(pwd)
REPONAME="https://github.com/saadiakhanam/java-maven-junit-helloworld.git"
TARGET_DIR="java-maven-junit-helloworld"
S3_BUCKET="jenkins3upload"
GITHUB_BRANCH="master"
###### Jobs Global Variables ########



########## Job Execution ##########
set_debug 
var_validation
build_project ${REPONAME}
s3_upload jenkins3upload
########## Job Execution ##########


####### Workspace Cleaning #####
rm -rf ${WORKSPACE}/*
####### Workspace Cleaning #####



