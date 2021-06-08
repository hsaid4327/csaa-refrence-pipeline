# csaa-refrence-pipeline
* [Introduction](#introduction)
* [Setup](#setup)

* [CI Pipeline](#ci-pipeline)
* [CD Pipeline](#cd-pipeline)
* [Pipeline Best Practices](#cd-pipeline)

## Introduction
## Setup
```
oc new-project csaa-jenkins
oc new-project csaa-dev
on new-project csaa-qa

oc policy add-role-to-user edit system:serviceaccount:csaa-jenkins:jenkins -n csaa-qa
oc policy add-role-to-user edit system:serviceaccount:csaa-jenkins:jenkins -n csaa-dev
oc policy add-role-to-user registry-viewer <user_name>
oc policy add-role-to-user registry-editor <user_name>

oc adm policy add-role-to-user edit  system:serviceaccount:csaa-jenkins:default -n csaa-dev

oc policy add-role-to-user system:image-puller opentlc-mgr -n csaa-dev

Note: for skope image promotion to quay from local ocp registry, requires token of the user opentlc-mgr like oc whoami -t

oc set env dc/myapp APP_MSG="All denizens of planet earth"
oc set triggers dc/myapp --manual -n csaa-dev
oc set triggers dc/myapp --manual -n csaa-qa

oc create secret docker-registry quay-secret --docker-server=quay.io --docker-username=hsaid4326 --docker-password=NabIla4327
oc new-app --as-deployment-config --name myapp --docker-image=quay.io/hsaid4326/my
```
### Jenkins Setup
## CI Pipeline
## CD Pipeline
## Pipeline Best Practices
