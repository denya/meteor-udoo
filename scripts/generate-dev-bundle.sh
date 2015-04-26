#!/usr/bin/env bash

set -e
set -u

WITHOUT_DEPENDENCIES=false
for arg in "$@"
do
    if [ "$arg" = "without-dependencies" ]; then
        WITHOUT_DEPENDENCIES=true
        break
    else
        echo "invalid argument: $arg"
        exit
    fi
done

UNAME=$(uname)
ARCH=$(uname -m)

if [ "$UNAME" == "Linux" ] ; then
    if [ "$ARCH" != "i686" -a "$ARCH" != "x86_64" -a "$ARCH" != "armv7l" ] ; then
        echo "Unsupported architecture: $ARCH"
        echo "meteor only supports armv7l, i686 and x86_64 for now."
        exit 1
    fi

    OS="linux"

    stripBinary() {
        strip --remove-section=.comment --remove-section=.note $1
    }
elif [ "$UNAME" == "Darwin" ] ; then
    SYSCTL_64BIT=$(sysctl -n hw.cpu64bit_capable 2>/dev/null || echo 0)
    if [ "$ARCH" == "i386" -a "1" != "$SYSCTL_64BIT" ] ; then
        # some older macos returns i386 but can run 64 bit binaries.
        # Probably should distribute binaries built on these machines,
        # but it should be OK for users to run.
        ARCH="x86_64"
    fi

    if [ "$ARCH" != "x86_64" ] ; then
        echo "Unsupported architecture: $ARCH"
        echo "Meteor only supports x86_64 for now."
        exit 1
    fi

    OS="osx"

    # We don't strip on Mac because we don't know a safe command. (Can't strip
    # too much because we do need node to be able to load objects like
    # fibers.node.)
    stripBinary() {
        true
    }
else
    echo "This OS not yet supported"
    exit 1
fi

PLATFORM="${UNAME}_${ARCH}"

SCRIPTS_DIR=$(dirname $0)
# cd "$SCRIPTS_DIR/.."
# CHECKOUT_DIR=$(pwd)

cd "`dirname "$0"`"/..
CHECKOUT_DIR=`pwd`

DIR=$(mktemp -d -t generate-dev-bundle-XXXXXXXX)
trap 'rm -rf "$DIR" >/dev/null 2>&1' 0

echo BUILDING IN "$DIR"

cd "$DIR"
chmod 755 .
umask 022
mkdir build
mkdir -p lib/node_modules/
cd build

# Read the bundle version from the meteor shell script.
BUNDLE_VERSION=$(perl -ne 'print $1 if /BUNDLE_VERSION=(\S+)/' meteor)
if [ -z "$BUNDLE_VERSION" ]; then
    echo "BUNDLE_VERSION not found"
    exit 1
fi

echo CHECKOUT DIR IS "$CHECKOUT_DIR"
echo BUILDING DEV BUNDLE "$BUNDLE_VERSION" IN "$DIR"

#if [ "$WITHOUT_DEPENDENCIES" != true ]; then

#git clone https://github.com/joyent/node.git
#cd node
# When upgrading node versions, also update the values of MIN_NODE_VERSION at
# the top of tools/main.js and tools/server/boot.js, and the text in
# docs/client/concepts.html and the README in tools/bundler.js.
#git checkout v0.11.14

cd "$DIR"

S3_HOST="s3.amazonaws.com/com.meteor.jenkins"

# Update these values after building the dev-bundle-node Jenkins project.
# Also make sure to update NODE_VERSION in generate-dev-bundle.ps1.
NODE_VERSION=0.10.36
NODE_BUILD_NUMBER=13
NODE_TGZ="node_${PLATFORM}_v${NODE_VERSION}.tar.gz"
if [ -f "${CHECKOUT_DIR}/${NODE_TGZ}" ] ; then
    tar zxf "${CHECKOUT_DIR}/${NODE_TGZ}"
else
    NODE_URL="https://${S3_HOST}/dev-bundle-node-${NODE_BUILD_NUMBER}/${NODE_TGZ}"
    echo "Downloading Node from ${NODE_URL}"
    curl "${NODE_URL}" | tar zx
fi

# Update these values after building the dev-bundle-mongo Jenkins project.
# Also make sure to update MONGO_VERSION in generate-dev-bundle.ps1.
MONGO_VERSION=2.6.7
MONGO_BUILD_NUMBER=6
MONGO_TGZ="mongo_${PLATFORM}_v${MONGO_VERSION}.tar.gz"
if [ -f "${CHECKOUT_DIR}/${MONGO_TGZ}" ] ; then
    tar zxf "${CHECKOUT_DIR}/${MONGO_TGZ}"
else
    MONGO_URL="https://${S3_HOST}/dev-bundle-mongo-${MONGO_BUILD_NUMBER}/${MONGO_TGZ}"
    echo "Downloading Mongo from ${MONGO_URL}"
    curl "${MONGO_URL}" | tar zx
fi

cd "$DIR/build"

# export path so we use our new node for later builds
export PATH="$DIR/bin:$PATH"

which node
which npm

# When adding new node modules (or any software) to the dev bundle,
# remember to update LICENSE.txt! Also note that we include all the
# packages that these depend on, so watch out for new dependencies when
# you update version numbers.

# First, we install the modules that are dependencies of tools/server/boot.js:
# the modules that users of 'meteor bundle' will also have to install. We save a
# shrinkwrap file with it, too.  We do this in a separate place from
# $DIR/server-lib/node_modules originally, because otherwise 'npm shrinkwrap'
# will get confused by the pre-existing modules.
mkdir "${DIR}/build/npm-server-install"
cd "${DIR}/build/npm-server-install"
node "${CHECKOUT_DIR}/scripts/dev-bundle-server-package.js" >package.json
npm install
npm shrinkwrap

mkdir -p "${DIR}/server-lib/node_modules"
# This ignores the stuff in node_modules/.bin, but that's OK.
cp -R node_modules/* "${DIR}/server-lib/node_modules/"

mkdir "${DIR}/etc"
mv package.json npm-shrinkwrap.json "${DIR}/etc/"

# Fibers ships with compiled versions of its C code for a dozen platforms. This
# bloats our dev bundle. Remove all the ones other than our
# architecture. (Expression based on build.js in fibers source.)
shrink_fibers () {
    FIBERS_ARCH=$(node -p -e 'process.platform + "-" + process.arch + "-v8-" + /[0-9]+\.[0-9]+/.exec(process.versions.v8)[0]')
    mv $FIBERS_ARCH ..
    rm -rf *
    mv ../$FIBERS_ARCH .
}

cd "$DIR/server-lib/node_modules/fibers/bin"
shrink_fibers

# Now, install the npm modules which are the dependencies of the command-line
# tool.
mkdir "${DIR}/build/npm-tool-install"
cd "${DIR}/build/npm-tool-install"
node "${CHECKOUT_DIR}/scripts/dev-bundle-tool-package.js" >package.json
npm install
# Refactor node modules to top level and remove unnecessary duplicates.
npm dedupe
cp -R node_modules/* "${DIR}/lib/node_modules/"

cd "${DIR}/lib"
#npm install request@2.33.0

#npm install fstream@1.0.2

#npm install tar@1.0.1

#npm install kexec@0.2.0

#npm install source-map@0.1.32

#npm install browserstack-webdriver@2.41.1
#rm -rf node_modules/browserstack-webdriver/docs
#rm -rf node_modules/browserstack-webdriver/lib/test

#npm install node-inspector@0.7.4

#npm install chalk@0.5.1

#npm install sqlite3@3.0.0
#rm -rf node_modules/sqlite3/deps

#npm install netroute@0.2.5

#npm install phantomjs@1.8.1-1
#rm -rf node_modules/phantomjs/tmp

#npm install https://github.com/meteor/node-http-proxy/tarball/99f757251b42aeb5d26535a7363c96804ee057f0

#npm install https://github.com/ariya/esprima/tarball/5044b87f94fb802d9609f1426c838874ec2007b3
#rm -rf node_modules/esprima/test

#npm install https://github.com/meteor/node-eachline/tarball/ff89722ff94e6b6a08652bf5f44c8fffea8a21da

#npm install jsdoc@3.3.0-alpha9
#rm -rf node_modules/jsdoc/node_modules/catharsis/node_modules/underscore-contrib
#rm -rf node_modules/jsdoc/node_modules/esprima/test

# Clean up some bulky stuff.
cd node_modules

if [ "$WITHOUT_DEPENDENCIES" != true ]; then

# Checkout and build mongodb.
# We want to build a binary that includes SSL support but does not depend on a
# particular version of openssl on the host system.

cd "$DIR/build"
OPENSSL="openssl-1.0.1g"
OPENSSL_URL="http://www.openssl.org/source/$OPENSSL.tar.gz"
wget $OPENSSL_URL || curl -O $OPENSSL_URL
tar xzf $OPENSSL.tar.gz

cd $OPENSSL
if [ "$UNAME" == "Linux" ]; then
    ./config --prefix="$DIR/build/openssl-out" no-shared
else
    # This configuration line is taken from Homebrew formula:
    # https://github.com/mxcl/homebrew/blob/master/Library/Formula/openssl.rb
    ./Configure no-shared zlib-dynamic --prefix="$DIR/build/openssl-out" darwin64-x86_64-cc enable-ec_nistp_64_gcc_128
fi
make install

# To see the mongo changelog, go to http://www.mongodb.org/downloads,
# click 'changelog' under the current version, then 'release notes' in
# the upper right.
cd "$DIR/build"
MONGO_VERSION="2.4.9"

# We use Meteor fork since we added some changes to the building script.
# Our patches allow us to link most of the libraries statically.
git clone git://github.com/meteor/mongo.git
cd mongo
git checkout ssl-r$MONGO_VERSION

# Used to delete bulky subtrees. It's an error (unlike with rm -rf) if they
# don't exist, because that might mean it moved somewhere else and we should
# update the delete line.
delete () {
    if [ ! -e "$1" ]; then
        echo "Missing (moved?): $1"
        exit 1
    fi
    rm -rf "$1"
}

delete browserstack-webdriver/docs
delete browserstack-webdriver/lib/test

delete sqlite3/deps
delete wordwrap/test
delete moment/min

# dedupe isn't good enough to eliminate 3 copies of esprima, sigh.
find . -path '*/esprima/test' | xargs rm -rf
find . -path '*/esprima-fb/test' | xargs rm -rf

# dedupe isn't good enough to eliminate 4 copies of JSONstream, sigh.
find . -path '*/JSONStream/test/fixtures' | xargs rm -rf

# Not sure why dedupe doesn't lift these to the top.
pushd cordova/node_modules/cordova-lib/node_modules/cordova-js/node_modules/browserify/node_modules
delete crypto-browserify/test
delete umd/node_modules/ruglify/test
popd

cd "$DIR/lib/node_modules/fibers/bin"
shrink_fibers

cd "$DIR"
stripBinary bin/node
stripBinary mongodb/bin/mongo
stripBinary mongodb/bin/mongod
fi

if [ "$WITHOUT_DEPENDENCIES" = true ]; then

mkdir -p "$DIR/mongodb/bin"
mkdir -p "$DIR/bin"

echo "#!/usr/bin/env bash" > "$DIR/mongodb/bin/mongo"
echo "mongo \"\$@\"" >> "$DIR/mongodb/bin/mongo"
chmod +x "$DIR/mongodb/bin/mongo"

echo "#!/usr/bin/env bash" > "$DIR/mongodb/bin/mongod"
echo "mongod \"\$@\"" >> "$DIR/mongodb/bin/mongod"
chmod +x "$DIR/mongodb/bin/mongod"

echo "#!/usr/bin/env bash" > "$DIR/bin/node"
echo "node \"\$@\"" >> "$DIR/bin/node"
chmod +x "$DIR/bin/node"

echo "#!/usr/bin/env bash" > "$DIR/bin/npm"
echo "npm \"\$@\"" >> "$DIR/bin/npm"
chmod +x "$DIR/bin/npm"

fi
# Download BrowserStackLocal binary.
BROWSER_STACK_LOCAL_URL="https://browserstack-binaries.s3.amazonaws.com/BrowserStackLocal-07-03-14-$OS-$ARCH.gz"

cd "$DIR/build"
curl -O $BROWSER_STACK_LOCAL_URL
gunzip BrowserStackLocal*
mv BrowserStackLocal* BrowserStackLocal
mv BrowserStackLocal "$DIR/bin/"

echo BUNDLING

cd "$DIR"
echo "${BUNDLE_VERSION}" > .bundle_version.txt
rm -rf build

tar czf "${CHECKOUT_DIR}/dev_bundle_${PLATFORM}_${BUNDLE_VERSION}.tar.gz" .

echo DONE
