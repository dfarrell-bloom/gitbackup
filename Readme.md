# GitBackup

## Goal

Provide a simple drop in place mechanism to be used with GitHub Web notifications so that each commit can be backed up beyond just on github.

## Motivation 

Github usually works great, but sometimes it goes down.  This little webapp aims to provide an alternate URL for SSH based read-only git access to be used as a starting point for github failover.

Github makes an HTTP POST with a Json payload, so a webserver must recieve that POST.  The payload contains all the data we need to know which repo.

## Implementation 

I chose a Ruby + Sinatra implementation for stack simplicity and ease of development.  Though the format of the push notification post JSON is taken from Github, the app is generic and can work to backup any git repository to which it has pull access.

At startup time, time, the application will issue a `git clone --mirror` for each repository listed in the `seed_repos` configuration settings.  (see below).  

Each time the application is notified via HTTP Post it will pull the repository.

Each backup is owned by a specified user - thus, the backed up repositories could potentially be owned each by a different user.  This allows some degree of access control between the different repositories - so, for example, a deployment key can be allowed to check out some of the repos, but not others.

### Config Options

* `token`: a somewhat secret token that allows push notifications and repo listing / log access.
   Though no harm _should_ be possible using this system ( and it certainly should never be given access
   to push to repositories anyway ), it would be unwise to use the default.  set it to some key that only you
   know.
* `public_keys`: a list of named public keys for use below.  Each will be allowed to pull the rpeo naming it as a public key ( see below )
* `public_keys`: a list of named private keys for use below.  One may be specified for each configured repo, used to authenticate against upstream (see below)
* `seed_repos`: a list of repos to back up.  
  * `name`: the directory in which to store the repo.
  * `url`: the origin of the repository (eg, what repo to back up)
  * `private_key`: the key of an ssh private key from `private_keys` above which has been granted access to pull the specified repo.  Note, this app
     has no business pushing to any repositories ( only pulling locally ) and so this key should have _readonly_ 
     access ( *Note*: a GitHub "Deployment Key" does _not_ have readonly access, as much sense as 
     that would make; I suggest creating a different deployment account for each use )
  * `user`: a user to own the repo.    The chef cookbooks provided create the user and assoicate the necessary private keys between the user that runs the backup program and the user that owns each repository backup.  
  * `public_keys`: an array of public key names, which refer to public keys from `public_keys` above which should have access to _pull_ this repo.  

## Chef Cookbook

The included chef cookbook can be used to deploy the app, set up the associated users, and manage ssh keys.

### Attributes

* `repository`: the url of the gitbackup repo to install 
* `checkout`: the branch to deploy 
* `user`: the use to run the github webapp 
* `home`: the home directory of `user`
* `webapp`: a hash of settings to be set for the webapp in `config.json`.  This allows the application config to be setup by chef.  Options are the same as for the configuration above; ssh keys will be managed.  

### Testing / Example

Kitchen was used to test the application and cookbook.  The default runlist calls all recipes and the associated serverspec test tests all functionality.  `.kitchen.yml` provides working examples of how one might configure the application in the real world.


