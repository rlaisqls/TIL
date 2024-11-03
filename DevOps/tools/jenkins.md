<https://jenkins-le-guide-complet.github.io/html/sec-hudson-home-directory-contents.html>

### Jenkins FileSystem

- .jenkins:  The default Jenkins home directory (may be .hudson in older installations).
- fingerprints:  This directory is used by Jenkins to keep track of artifact fingerprints. We look at how to track artifacts later on in the book.
- jobs:  This directory contains configuration details about the build jobs that Jenkins manages, as well as the artifacts and data resulting from these builds. We look at this directory in detail below.
- plugins:  This directory contains any plugins that you have installed. Plugins allow you to extend Jenkins by adding extra feature. Note that, with the exception of the Jenkins core plugins (subversion, cvs, ssh-slaves, maven, and scid-ad), plugins are not stored with the jenkins executable, or in the expanded web application directory. This means that you can update your Jenkins executable and not have to reinstall all your plugins.
- updates:  This is an internal directory used by Jenkins to store information about available plugin updates.
- userContent:  You can use this directory to place your own custom content onto your Jenkins server. You can access files in this directory at <http://myserver/hudson/userContent> (if you are running Jenkins on an application server) or <http://myserver/userContent> (if you are running in stand-alone mode).
- users:  If you are using the native Jenkins user database, user accounts will be stored in this directory.
- war:  This directory contains the expanded web application. When you start Jenkins as a stand-alone application, it will extract the web application into this directory.

```
JENKINS_HOME
 +- builds            (build records)
    +- [BUILD_ID]     (subdirectory for each build)
         +- build.xml      (build result summary)
         +- changelog.xml  (change log)
 +- config.xml         (Jenkins root configuration file)
 +- *.xml              (other site-wide configuration files)
 +- fingerprints       (stores fingerprint records, if any)
 +- identity.key.enc   (RSA key pair that identifies an instance)
 +- jobs               (root directory for all Jenkins jobs)
     +- [JOBNAME]      (sub directory for each job)
         +- config.xml (job configuration file)
     +- [FOLDERNAME]   (sub directory for each folder)
         +- config.xml (folder configuration file)
         +- jobs       (subdirectory for all nested jobs)
 +- plugins            (root directory for all Jenkins plugins)
     +- [PLUGIN]       (sub directory for each plugin)
     +- [PLUGIN].jpi   (.jpi or .hpi file for the plugin)
 +- secret.key         (deprecated key used for some plugins' secure operations)
 +- secret.key.not-so-secret  (used for validating _$JENKINS_HOME_ creation date)
 +- secrets            (root directory for the secret+key for credential decryption)
     +- hudson.util.Secret   (used for encrypting some Jenkins data)
     +- master.key           (used for encrypting the hudson.util.Secret key)
     +- InstanceIdentity.KEY (used to identity this instance)
 +- userContent        (files served under your https://server/userContent/)
 +- workspace          (working directory for the version control system)
```
