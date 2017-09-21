#!/usr/bin/env bash


PLUGIN_NAME=EC-ISPW
PLUGIN_VERSION=1.0.0.0
DIR=$(dirname $0)
chmod +x $DIR/../bin/linux_x86_64/ecpluginbuilder
$DIR/../bin/linux_x86_64/ecpluginbuilder --plugin-version $PLUGIN_VERSION

ectool installPlugin $DIR/../build/$PLUGIN_NAME.zip
ectool promotePlugin $PLUGIN_NAME-$PLUGIN_VERSION
ectool setProperty /projects/$PLUGIN_NAME-$PLUGIN_VERSION/debugLevel 10


