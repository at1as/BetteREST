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

### Usage

The easiest way to use BetteR is to install it using the [Ruby Gem](http://rubygems.org/gems/better_rest) (note that I usually keep the gem several commits behind the github repo):
```bash
$ gem install better_rest
```
Or download the repository here for the latest version and launch via:
```bash
$ ./bin/better_rest
```
To try BetteR, without installing the Gem, it's also hosted on [Heroku](http://better-rest.herokuapp.com/). Note that when run on Heroku, the build is likely to be from a much older commit.

### Dependencies

See Gemfile for dependencies

### TODO

* OAuth/OAuth2 support
* Update current deprecated Basic/Digest Auth method
* Download to file
* Support more than one variable
* Delete logs (front-end)
