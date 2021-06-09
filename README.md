# csaa-refrence-pipeline
* [Introduction](#introduction)
* [Setup](#setup)

* [CI Pipeline](#ci-pipeline)
* [CD Pipeline](#cd-pipeline)
* [Pipeline Best Practices](#cd-pipeline)

## Introduction
This repository contains an application and pipeline code to demonstrate CICD pipeline for a basic spring application using Jenkins and OCP 4.7.
### Assumptions
* Jenkins is running inside OCP as a container built from the Jenkins image provided by OCP
* Jenkins is running in an OCP project csaa-jenkins
* Image is built in the OCP project csaa-dev
* Image is deployed for development in csaa-dev and csaa-qa
* Jenkins needs to be configured with Pod template to enable a Jenkins agent. This is used in CD pipeline
* The image is pushed from the OCP internal registry to Quay registry.
* The credentials for Quay and Git repository needs to be configured in Jenkins and Openshift build project

## Setup
### Seting up Projects
```

oc new-project csaa-jenkins
oc new-project csaa-dev
on new-project csaa-qa
```

### Setup a secret for Quay registry
```
oc create secret docker-registry quay-secret --docker-server=quay.io --docker-username=<repo> --docker-password=<password> -n csaa-dev
oc create secret docker-registry quay-secret --docker-server=quay.io --docker-username=<repo> --docker-password=<password> -n csaa-qa
```

### Build the application Code
Get the application code from : https://github.com/hsaid4327/csaa-refrence-pipeline.git
Build the application code using the script directory app-src:

```
git clone https://github.com/hsaid4327/csaa-refrence-pipeline.git
cd app-src
./buildMaven <version>
```

### Setup application BuildConfig in Dev project and build the image
```
oc new-build -i jboss-eap70-openshift:1.7 --binary=true --name myapp -n csaa-dev
oc start-build myapp --from-dir=myapp
```
 ### Setup of application resources in the dev and qa projects
This step sets up the application resources such as deploymentConfig, service and routes in the targeted projects

```
oc process -f template-csaa-app-setup.yaml -p NAMESPACE=csaa -p APP_MSG=test -p IMAGE_TAG=stable | oc create -f -  
```
### Jenkins Setup

#### Setup the Jenkins server in csaa-qa project:
```
  oc new-app --template jenkins-ephemeral -n csaa-qa 
```
#### Grant Jenkins serviceaccounts permissions to deploy application is csaa-dev and csaa-qa projects:
```
oc policy add-role-to-user edit system:serviceaccount:csaa-jenkins:jenkins -n csaa-qa
oc policy add-role-to-user edit system:serviceaccount:csaa-jenkins:jenkins -n csaa-dev
oc adm policy add-role-to-user edit  system:serviceaccount:csaa-jenkins:default -n csaa-dev
oc adm policy add-role-to-user edit  system:serviceaccount:csaa-jenkins:default -n csaa-qa

```
#### Setup global credentials in jenkins
The pipeline requires access to Git repo, Quay and Openshift registries. That requires setting up credentials in Jenkins:
  Manage Jenkins -> Credentials ---> Global ---> add credentials
Add the credentials with the following names:
* For quay: quay-creds
* For github: github-creds
* For OCP registry: ocp-registry-creds
For example for Quay you define the creds in the screen like this:
  
 ![](images/jenkins-creds.png?raw=true)
* Note: For setting up OCP registry credential, use the following for the password (name could be the username of the admin)
```
oc sa get-token jenkins
```
### Setup Jenkins Pod Template
Though we are using a repo controlled Pod template for defining Kubernetes agents to run the pipelines as in CI pipeline, just for demo purposes and flexibility we have also defined pod template using Jenkins UI.
Pod template can be configured by going to Manage Nodes And Clouds --> Configure Clouds ---> Pod template
This opens up the window for defining and pod an container templates:

 jnlp container:
 ![](images/pod-template-jnlp.png?raw=true)
 
 skopeo container:
 ![](images/pod-template-jnlp.png?raw=true)

## CI Pipeline
The CI pipelin is used to build the code and push the image to external Quay registry. The pipeline is defined in the Git repository and is configured on Jenkins
UI by creating a New Item for Pipeline and selecting *pipeline script from SCM*. This show in the image below:
![](images/pipeline-setup.png?raw=true) 
In the script path put ci/Jenkinsfile


## CD Pipeline
The CD pipeline is used to deploy application on csaa-dev or csaa-qa projects. The parameters allow the user to select number of application replicas and message to set on the deploymentconfig. Also the application version can be specified too:
![](images/cd-params.png?raw=true)

For deployment to csaa-qa, the deployment toggles between blue and green versions of the application.
For testing of the application csaa-qa, get the route by:
```
oc project csaa-qa
oc get route
http://<route>/hello/api/hello
```
For testing of the application on csaa-dev, get the route by:
```
oc project csaa-qa
oc get route
http://<route>/hello/api/hello
```
## Pipeline Best Practices
These are some of the recommendations for pipeline implmentation:
* A trick for speeding up the pipeline for Jenkins running inside openshift:
 ```
 oc set env dc/jenkins JENKINS_JAVA_OVERRIDES="-Dhudson.slaves.NodeProvisioner.initialDelay=0 -Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85 -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.HEARTBEAT_CHECK_INTERVAL=300"
 ```
* Use Jenkin agents to pervent clogging the Jenkins master 
* To seperate the execution of pipeline from the definition of OCP resources, use Templates/Helm charts for deployment and configuration
* There is a debate about using Openshift DSL vs oc client commands. For portability and for ease of use, I would recommend using oc client commands. There can be a mix of both, as using DSL would demaracate cluster and project boundaries and any DSL command exectuted is within that context
* Use external registry for storing images. The current pipeline uses Quay.
* According to DevOps gospel, every build is potential release. With that in mind avoid using Maven release plugin which uses SNAPSHOTS. Use pom version with semantic versioning to tag every image build. 
