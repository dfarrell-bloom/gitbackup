= GitBackup

== Goal

Provide a simple drop in place mechanism to be used with GitHub Web notifications so that each commit can be backed up beyond just on github.

== Motivation 

Github usually works great, but sometimes it goes down.  This little webapp aims to provide an alternate URL for SSH based read-only git access to be used as a starting point for github failover.

== Architecture

makes an HTTP POST with a Json payload, so a webserver must recieve that POST.  The payload contains all the data we need to know which repo.

We will use the filesystem itself to track the repositories and store them, using heuristics to map the repository info to filesystem locations.

== Implementation 

I chose a Ruby + Sinatra implementation for stack simplicity and ease of development.  

=== REST Endpoints

POST / - Github push notification

GET  / - Global Status

GET /:id 


