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

## Slow Start (for developers)

If you want to run on the bleeding edge, or help develop Meteor, you
can run Meteor directly from a git checkout.

    git clone git://github.com/meteor/meteor.git
    cd meteor

If you're the sort of person who likes to build everything from scratch,
you can build all the Meteor dependencies (node.js, npm, mongodb, etc)
with the provided script. This requires git, a C and C++ compiler,
autotools, and scons. If you do not run this script, Meteor will
automatically download pre-compiled binaries when you first run it.

    # OPTIONAL
    ./scripts/generate-dev-bundle.sh

Now you can run meteor directly from the checkout (if you did not
build the dependency bundle above, this will take a few moments to
download a pre-build version).

    ./meteor --help

From your checkout, you can read the docs locally. The `/docs` directory is a
meteor application, so simply change into the `/docs` directory and launch
the app:

    cd docs/
    ../meteor

You'll then be able to read the docs locally in your browser at
`http://localhost:3000/`.

Note that if you run Meteor from a git checkout, you cannot pin apps to specific
Meteor releases or run using different Meteor releases using `--release`.

## Uninstalling Meteor

Aside from a short launcher shell script, Meteor installs itself inside your
home directory. To uninstall Meteor, run:

    rm -rf ~/.meteor/
    sudo rm /usr/local/bin/meteor

## Developer Resources

Building an application with Meteor?

* Announcement list: sign up at http://www.meteor.com/
* Ask a question: http://stackoverflow.com/questions/tagged/meteor
* Meteor help and discussion mailing list: https://groups.google.com/group/meteor-talk
* IRC: `#meteor` on `irc.freenode.net`

Interested in contributing to Meteor?

* Core framework design mailing list: https://groups.google.com/group/meteor-core
* Contribution guidelines: https://github.com/meteor/meteor/tree/devel/Contributing.md

We are hiring!  Visit https://www.meteor.com/jobs/working-at-meteor to
learn more about working full-time on the Meteor project.
>>>>>>> release/METEOR@1.0

Your project should now be running as a service. It is started automatically on boot, and restarted if it should crash.
 * Use `sudo svstat /etc/service/meteor` to check its status
 * Use `sudo svc -d /etc/service/meteor` to stop the service
 * Use `sudo svc -u /etc/service/meteor` to start the service
 * Use `sudo svc -t /etc/service/meteor` to restart the service
-->
