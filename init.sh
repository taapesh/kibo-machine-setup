#!/usr/bin/env bash

# Preserve pwd for later
BASE_DIR=$(pwd)

# Setup .bash_profile
read -p "Setup bash profile? [y/n] " -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	cat bash_profile.txt > ~/.bash_profile
	source ~/.bash_profile
fi

if [ ! -d $MARKETLIVE_HOME ];
then
	# Setup marketlive directory
	echo "Your marketlive home directory is not set, creating it now..."
	cd ~
	mkdir -p $MARKETLIVE_HOME
	sudo chown $USER:staff $MARKETLIVE_HOME
	mkdir -p $MARKETLIVE_HOME/sites
	echo "Done"
fi
echo

read -p "Install homebrew and required packages? [y/n] " -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Install XCode command line tools if not already installed
	xcode-select --install

	# Install homebrew if not already installed
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

	# Install maven
	brew install maven

	# Install rabbitmq
	brew install rabbitmq
fi
echo

read -p "Would you like to download marketlive files? [y/n] " -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Grab marketlive files from svn
	# sudo svn export https://ps-svn.aws.marketlive.com/marketlive/tools $MARKETLIVE_HOME/tools --force
	# sudo svn export https://ps-svn.aws.marketlive.com/marketlive/images $MARKETLIVE_HOME/images --force
	# sudo svn export https://ps-svn.aws.marketlive.com/marketlive/libraries $MARKETLIVE_HOME/libraries --force
	# sudo svn export https://ps-svn.aws.marketlive.com/marketlive/release $MARKETLIVE_HOME/release --force

	# Extract folders because it is faster (svn method takes > 1 hour on wifi)
	unzip -o $BASE_DIR/ecom_files/ecom_tools.zip -d $MARKETLIVE_HOME
	unzip -o $BASE_DIR/ecom_files/ecom_release.zip -d $MARKETLIVE_HOME
	unzip -o $BASE_DIR/ecom_files/ecom_tomcat.zip -d $MARKETLIVE_HOME
	unzip -o $BASE_DIR/ecom_files/ecom_images.zip -d $MARKETLIVE_HOME
	unzip -o $BASE_DIR/ecom_files/ecom_libraries.zip -d $MARKETLIVE_HOME
	chmod +x $MARKETLIVE_HOME/tomcat/apache-tomcat-7.0.52/bin/*
fi
echo

read -p "Setup mongo? [y/n] " -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Setup mongo
	sudo mkdir -p /data/db
	sudo chmod 777 /data/db
	echo "Installing mongodb"
	sudo cp -R $BASE_DIR/mongo $MARKETLIVE_HOME/mongo

	echo "Installing MongoDB Launchctl Item and Restarting Mongo";

	# Create temporary org.mongo.mongod.plist file
	sudo touch org.mongo.mongod.plist
	sudo chmod 777 org.mongo.mongod.plist
	sudo cat copy.org.mongo.mongod.plist | sed -e "s#{marketlive_home}#$MARKETLIVE_HOME#" > org.mongo.mongod.plist
	
	# create mongo directories
	sudo chmod 777 $MARKETLIVE_HOME/mongo
	mkdir -vp $MARKETLIVE_HOME/mongo/data/db
	mkdir -vp $MARKETLIVE_HOME/mongo/data/log/
	sudo touch $MARKETLIVE_HOME/mongo/data/log/mongodb.log

	# copy PLIST and (re)install it
	sudo cp $BASE_DIR/org.mongo.mongod.plist /Library/LaunchDaemons/ 
	sudo chown root:wheel /Library/LaunchDaemons/org.mongo.mongod.plist 
	launchctl stop org.mongo.mongod
	launchctl unload /Library/LaunchDaemons/org.mongo.mongod.plist
	launchctl load /Library/LaunchDaemons/org.mongo.mongod.plist 
	launchctl start org.mongo.mongod
	sudo rm org.mongo.mongod.plist
	echo "FINISHED";
fi
echo

# Edit settings files located in /.m2 directory
# Setup master password in settings-security.xml
# Setup nexus username and nexus password in settings.xml
read -p "Set a new master password? [y/n] " -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mkdir -p ~/.m2
    echo -n "Enter a master password for settings-security.xml: "
	read -s MASTER
	MASTER="$(mvn --encrypt-master-password MASTER | sed 's/\//\\\//g')"
	echo "Master password set"
	echo $MASTER
	cat $BASE_DIR/settings-security-clean.xml | sed "s/{pass}/${MASTER}/" > ~/.m2/settings-security.xml
fi
echo

read -p "Set a new nexus username/password? [y/n] " -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo -n "Nexus server username (ml.username): "
	read NEXUS_USER
	echo "Nexus username set"
	echo $NEXUS_USER
	echo -n "Nexus server password: "
	read -s NEXUS_PASS
	NEXUS_PASS="$(mvn --encrypt-password NEXUS_PASS | sed 's/\//\\\//g')"
	echo "Nexus password set"
	echo $NEXUS_PASS
	cat $BASE_DIR/settings-clean.xml | sed -e "s/{mlUser}/${NEXUS_USER}/" | sed -e "s/{mlPass}/${NEXUS_PASS}/" > ~/.m2/settings.xml
fi
echo

read -p "Set up SSH key? [y/n] " -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	ssh -o ConnectTimeout=6 root@192.168.56.101 exit
fi
echo

echo DONE