// import java.io.File
// 
// def procName = 'Download Files - Topaz 18.2.3+'
// procedure procName, description: 'Use the ISPW CLI to download source code or other component files. This version of the Download Files procedure is compatible with the 18.2.3 version of the Topaz CLI (released October 2017), but not with earlier versions.', {
//     description: 'Use the ISPW CLI to download source code or other component files'
//     resourceName: '$[/myPlugin/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]'
// 
//     step 'Transfer Credential',
//         command: new File(pluginDir, "dsl/procedures/$procName/steps/Transfer Credential.pl").text,
//         condition: '$[/javascript "$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/proxyHostName]".length > 0]',
//         description: 'If the topazCLIAgent is a proxy agent, then use code copied from ecproxy.pl to make an ssh connection to the same machine that the topazCLIAgent proxies to, and use it to put the user name and password in restricted-access files in a subdirectory called TopazCliWkspc in the externalToolsWs directory',
//         errorHandling: 'abortProcedure',
//         shell: 'ec-perl'
//         
//     step 'Download Files (UNIX)',
//         command: new File(pluginDir, "dsl/procedures/$procName/steps/Download Files (UNIX).sh").text,
//         condition: '$[/javascript ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\".slice(-1) == \"x\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"sh \") >= 0 ) ]',
//         errorHandling: 'abortProcedure',
//         parallel: '1',
//         postProcessor: 'postp',
//         resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
//         workingDirectory: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIWorkspace]'
//         
//     step 'Download Files (Windows)',
//         command: new File(pluginDir, "dsl/procedures/$procName/steps/Download Files (Windows).bat").text,
//         condition: '$[/javascript ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\" == \"windows\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"cmd \") == 0 ) ]',
//         errorHandling: 'abortProcedure',
//         parallel: '1',
//         postProcessor: 'postp',
//         resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
//         workingDirectory: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIWorkspace]'
// }
  
