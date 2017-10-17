cd "$[externalToolsWs]"
mkdir TopazCliWkspc\ 2> NUL
cd TopazCliWkspc\
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
cd "$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIDirectory]"
SET "JRE_HOME=$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/jreHome]"
"$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIDirectory]\TotalTestCLI.bat" -cmd=runtest -host=$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSHost] -port=$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/zOSPort] "-user=%USERNAME%" "-pw=%PASSWORD%" "-project=$[projectPath]" "-testsuitelist=$[testSuiteList]" "-jcl=$[jcl]" "-externaltoolsws=$[externalToolsWs]" -postruncommands=copyjunit,copysonar -data="$[externalToolsWs]\TopazCliWkspc" $[/javascript ('$[dSNHLQ]'.length > 0) ? '"-dsnhlq=$[dSNHLQ]"' : ''] $[/javascript ('$[useStubs]'.length > 0) ? '"-usestubs=$[useStubs]"' : ''] $[/javascript ('$[deleteTemp]'.length > 0) ? '"-deletetemp=$[deleteTemp]"' : ''] $[/javascript ('$[cCRepo]'.length > 0) ? '"-ccrepo=$[cCRepo]" "-ccsystem=$[cCSystem]" "-cctestid=$[cCTestID]" "-ccdb2=$[cCDB2]"' : '']
