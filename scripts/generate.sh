#!/usr/bin/env bash


DIR=$(dirname $0)
REST_PLUGIN_WIZARD_DIR=$DIR/../../RESTPluginWizard
PLUGIN_WIZARD_DIR=$DIR/../../PluginWizard


ec-perl $REST_PLUGIN_WIZARD_DIR/build.pl --workspace $DIR/../.. --plugin-name EC-Compuware-Topaz \
--plugin-wizard-folder $PLUGIN_WIZARD_DIR --config-path $DIR/../config/ispw-cli.yml
