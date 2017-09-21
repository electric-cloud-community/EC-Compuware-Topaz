cd $[externalToolsWs]
mkdir TopazCliWkspc\ 2> NUL
cd $[topazCLIDirectory]
SET "JRE=$[jreHome]"
"$[topazCLIDirectory]\TotalTestCLI.bat" -cmd=runtest -host=$[host] -port=$[port] "-user=$[user]" "-pw=$[pw]" "-project=$[projectName]" "-testsuitelist=$[testSuite]" "-jcl=$[jcl]" "-externaltoolsws=$[externalToolsWs]" -postruncommands=copyjunit,copysonar -data="$[externalToolsWs]\TopazCliWkspc"