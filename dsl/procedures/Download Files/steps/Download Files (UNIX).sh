cd "$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIDirectory]"
JRE_HOME="$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/jreHome]"
export JRE_HOME
cd "$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIWorkspace]"
if [ -f eccp ]; then
  USERNAME=`cat eccu`
  PASSWORD=`cat eccp`
  chmod 600 eccu eccp
  rm -f eccu eccp
else
  USERNAME=`ectool getFullCredential $[configurationName] --value userName`
  PASSWORD=`ectool getFullCredential $[configurationName] --value password`
fi
"$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIDirectory]/TopazCLI.sh" -host $[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSHost] -port $[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSPort] -id "$USERNAME" -pass "$PASSWORD" -code "$[codePage]" -scm ispw -targetFolder "$[targetFolder]" -data "$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIWorkspace]" -ispwServerStream "$[serverStream]" -ispwServerApp "$[serverApplication]" -ispwServerLevel "$[serverLevel]" -ispwLevelOption $[levelOption] $[/javascript ('$[serverConfig]'.length > 0) ? '-ispwServerConfig "$[serverConfig]"' : ''] $[/javascript ('$[filterName]'.length > 0) ? '-ispwFilterName "$[filterName]"' : ''] $[/javascript ('$[filterType]'.length > 0) ? '-ispwFilterType "$[filterType]"' : '']