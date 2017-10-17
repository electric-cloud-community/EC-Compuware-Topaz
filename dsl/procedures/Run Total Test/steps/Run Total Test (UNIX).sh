cd "$[externalToolsWs]"
mkdir -p TopazCliWkspc/
cd TopazCliWkspc
if [ -f eccp ]; then
  USERNAME=`cat eccu`
  PASSWORD=`cat eccp`
  chmod 600 eccu eccp
  rm -f eccu eccp
else
  USERNAME=`ectool getFullCredential $[configurationName] --value userName`
  PASSWORD=`ectool getFullCredential $[configurationName] --value password`
fi
cd "$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIDirectory]"
JRE_HOME="$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/jreHome]"
export JRE_HOME
"$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIDirectory]/TotalTestCLI.sh" -cmd=runtest -host=$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSHost] -port=$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSPort] "-user=$USERNAME" "-pw=$PASSWORD" "-project=$[projectPath]" "-testsuitelist=$[testSuiteList]" "-jcl=$[jcl]" "-externaltoolsws=$[externalToolsWs]" -postruncommands=copyjunit,copysonar -data="$[externalToolsWs]\TopazCliWkspc" $[/javascript ('$[dSNHLQ]'.length > 0) ? '"-dsnhlq=$[dSNHLQ]"' : ''] $[/javascript ('$[useStubs]'.length > 0) ? '"-usestubs=$[useStubs]"' : ''] $[/javascript ('$[deleteTemp]'.length > 0) ? '"-deletetemp=$[deleteTemp]"' : ''] $[/javascript ('$[cCRepo]'.length > 0) ? '"-ccrepo=$[cCRepo]" "-ccsystem=$[cCSystem]" "-cctestid=$[cCTestID]" "-ccdb2=$[cCDB2]"' : '']
