# BetteR [![Build Status](https://travis-ci.org/at1as/BetteR.svg?branch=master)](https://travis-ci.org/at1as/BetteR) [![Gem Version](https://badge.fury.io/rb/better_rest.svg)](http://badge.fury.io/rb/better_rest)

BetteR is a a REST test client written in Ruby and served by Sinatra.

BetteR emphasises both a clean and easy to use interface, as well as allowing users to have a very granuler control over their requests (things like following redirects, verbosity of response and timeout intervals are all configurable). The current feature set is modest, but what it does, it aims to do well.

### Screenshot

![Screenshot](http://at1as.github.io/github_repo_assets/better-rest-client.jpg)

### Features

* Import collections from POSTMAN
* Save and load Requests
* Attach files to requests
* Send parallel requests
* Use in your preferred browser
* Save session cookies

### Usage

The easiest way to use BetteR is to install it using the [Ruby Gem](http://rubygems.org/gems/better_rest) (note that the gem is usually a few commits behind the github repo):
```bash
$ gem install better_rest
```
Or download the repository here for the latest version. Assign appropriate execute permissions, open port 5678 (on remote instances) and launch via:
```bash
$ git clone https://github.com/at1as/BetteR.git
$ ./bin/better_rest
$ Navigate browser to http://0.0.0.0:5678 (local) or http://X.X.X.X:5678 (remote server)
```
To try BetteR, without installing the Gem, it's also hosted on [Heroku](http://better-rest.herokuapp.com/). Note that when run on Heroku internally hosted APIs can't be tested and that it's not currently session based, so multiple concurrent users may result in unexpected behaviour.

### Dependencies

See Gemfile for a list of dependencies

### TODO

* OAuth/OAuth2 support
* Update current deprecated Basic/Digest Auth method
* Download to file
* Support more than one variable
* Support for multiple concurrent sessions
