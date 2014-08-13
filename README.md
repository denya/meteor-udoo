# Meteor for UDOO

Meteor is an ultra-simple environment for building modern web
applications.

This project aims to get Meteor running on UDOO, including the node.js package node-udoo.

Read more about Meteor on [Meteors GitHub project page](http://github.com/meteor/meteor/), and about node-udoo on the [node-udoo GitHub project page](https://github.com/pilwon/node-udoo).

## Step 1: Setting up the environment

 1. [Download and install Debian Wheezy armHF](http://www.udoo.org/downloads/)
 2. Configure WiFi so that it gets connected automatically
 3. (optional) Give the UDOO a fixed IP on your router
 4. (optional) Assign the local IP to DMZ and assign a dynamic DNS to it
 5. Enable the two [network interfaces in /etc/network/interfaces](http://www.unix.com/ip-networking/211031-unable-connect-localhost-debian-6-a.html). You'll probably want to install your favorite text editor (maybe vim) at this point so that you can edit the interface file. After having edited it; reboot to activate the interfaces.
 6. [Set the locale](https://wiki.debian.org/ChangeLanguage)
 7. [Enable the debian testing and unstable repositories](http://serverfault.com/a/382101). You can probably get away with just enabling the testing repo, but I followed the instructions precisely.
 8. `sudo apt-get install screen` (optional, but using screen makes everything easier. I recommend you run all of the following steps through screen.)
 9. `sudo apt-get update && sudo apt-get upgrade`
 10. `sudo apt-get install mongodb mongodb-server mongodb-clients mongodb-dev`
 11. `sudo apt-get install nodejs npm`
 12. `sudo ln --symbolic /usr/bin/nodejs /usr/bin/node` Node.JS is installed as "nodejs" instead of the more common "node" for some reason.
 13. `sudo apt-get install authbind`
 14. `sudo touch /etc/authbind/byport/80 /etc/authbind/byport/81`
 15. `sudo chown debian:debian /etc/authbind/byport/80 /etc/authbind/byport/81`
 16. `chmod +x /etc/authbind/byport/80 /etc/authbind/byport/81` (MongoDB will bind to one port above your HTTP port which is why we need to make 81 available)

## Step 2: Building Meteor

 13. `sudo apt-get install git`
 14. `cd ~ && git clone https://github.com/josteinaj/meteor-udoo.git`
 15. `cd ~/meteor-udoo && ./scripts/generate-dev-bundle.sh without-dependencies`
 16. ``sudo ln --symbolic ~/meteor-udoo/meteor /usr/bin/meteor``
 17. Now you should be able to use the `meteor` command to your hearts content! Use `authbind --deep meteor --port 80` to bind to port 80

* **TODO**: installing udoo npm

## Step 3: Running Meteor as a daemon

 18. Edit `~/meteor-udoo/run-service.sh` and set `PROJECT_DIR` to the absolute path to your meteor project. For instance, try setting it to the meteor "docs" project.
 19. Run `crontab -e` (as a normal user) and add `* * * * * /home/debian/meteor-udoo/run-service.sh` to the end of the file

Once a minute, this will check if your meteor project is running, and start it if it isn't. So if for some reason it crashes it will restart; but most importantly, it will start automatically on boot.

<!--
 I haven't got this working yet but this would probably be a better setup:

[Based on this stackoverflow answer](http://stackoverflow.com/a/2467513/281065).

 18. Edit `~/meteor-udoo/run-service.sh` and set `PROJECT_DIR` to the absolute path to your meteor project. The default is the meteor "docs" project.
 19. `sudo apt-get install daemontools daemontools-run svtools`
 20. `cd ~ && wget http://codepad.org/9CgRVihO/raw.pl -O mkservice.pl && chmod +x mkservice.pl`
 21. `sudo ~/mkservice.pl -d /etc/service/meteor -l -u debian -L debian "/home/debian/meteor-udoo/run-service.sh"`

Your project should now be running as a service. It is started automatically on boot, and restarted if it should crash.
 * Use `sudo svstat /etc/service/meteor` to check its status
 * Use `sudo svc -d /etc/service/meteor` to stop the service
 * Use `sudo svc -u /etc/service/meteor` to start the service
 * Use `sudo svc -t /etc/service/meteor` to restart the service
-->
