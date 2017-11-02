cd "$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIDirectory]"
SET "JRE_HOME=$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/jreHome]"
cd "$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIWorkspace]"
IF EXIST eccp (
  set USERNAME=
  for /f "delims=" %%a in ('type eccu') do @set USERNAME=%%a
  set PASSWORD=
  for /f "delims=" %%a in ('type eccp') do @set PASSWORD=%%a
  attrib -R -S -H eccu
  del eccu
  attrib -R -S -H eccp
  del eccp
) ELSE (
  set USERNAME=
  for /f "delims=" %%a in ('ectool getFullCredential $[configurationName] --value userName') do @set USERNAME=%%a
  set PASSWORD=
  for /f "delims=" %%a in ('ectool getFullCredential $[configurationName] --value password') do @set PASSWORD=%%a
)
"$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIDirectory]\SCMDownloaderCLI.bat" -host $[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSHost] -port $[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSPort] -id "%USERNAME%" -pass "%PASSWORD%" -code "$[codePage]" -timeout "$[timeout]" -scm ispw -targetFolder "$[targetFolder]" -data "$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIWorkspace]" -ispwServerStream "$[serverStream]" -ispwServerApp "$[serverApplication]" -ispwServerLevel "$[serverLevel]" -ispwLevelOption "$[levelOption]" -ispwFilterFiles "$[filterFiles]" -ispwFilterFolders "$[filterFolders]" $[/javascript ('$[serverConfig]'.length > 0) ? '-ispwServerConfig "$[serverConfig]"' : ''] $[/javascript ('$[folderName]'.length > 0) ? '-ispwFolderName "$[folderName]"' : ''] $[/javascript ('$[componentType]'.length > 0) ? '-ispwComponentType "$[componentType]"' : '']