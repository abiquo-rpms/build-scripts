# SETUP

## Clone the build-scripts repo

	git clone https://github.com/abiquo-rpms/build-scripts
	build-scripts

## Install the required packages

### Debian/Ubuntu

1. Install required packages
  
	sudo apt-get install build-essential ruby ruby-dev libcurl4-openssl-dev rubygems

### RHEL 6

1. Install EPEL Repo (as root)

	rpm -Uvh http://download.fedora.redhat.com/pub/epel/6/x86_64/epel-release-6-5.noarch.rpm

2. Install required packages (as root)
  
	yum install yum-utils ruby-devel gcc make automake ruby rubygems curl-devel gcc-c++

### RHEL 5

1. Install EPEL Repo (as root)

	rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm

2. Install required packages (as root)
  
	yum install yum-utils ruby-devel gcc make automake ruby rubygems curl-devel gcc-c++


## Install the required gems
 
	sudo gem install rest-client pkg-wizard streamly


USAGE
------

* Generate and build all the RPMS (platform, libraries and related packages, ~40 pkgs)

  ./bootstrap.rb --all

* Generate and build platform packages
 
  ./bootstrap.rb  

* Do not fetch/refresh packages from github when building

  ./bootstrap.rb --skip-fetch
