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
"$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIDirectory]/SCMDownloaderCLI.sh" -host $[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSHost] -port $[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSPort] -id "$USERNAME" -pass "$PASSWORD" -code "$[codePage]" -timeout "$[timeout]" -scm ispw -targetFolder "$[targetFolder]" -data "$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIWorkspace]" -ispwServerStream "$[serverStream]" -ispwServerApp "$[serverApplication]" -ispwServerLevel "$[serverLevel]" -ispwLevelOption "$[levelOption]" -ispwFilterFiles "$[filterFiles]" -ispwFilterFolders "$[filterFolders]" $[/javascript ('$[serverConfig]'.length > 0) ? '-ispwServerConfig "$[serverConfig]"' : ''] $[/javascript ('$[folderName]'.length > 0) ? '-ispwFolderName "$[folderName]"' : ''] $[/javascript ('$[componentType]'.length > 0) ? '-ispwComponentType "$[componentType]"' : '']