import java.io.File

// def procName = 'Download Files - Topaz 18.2.2-'
// procedure procName, description: 'Use the ISPW CLI to download source code or other component files. This version of the Download Files procedure is compatible with the 18.2.2 version of the Topaz CLI (released July 2017), but not with later versions.', {
def procName = 'Download Files'
procedure procName, description: 'Use the ISPW CLI to download source code or other component files.', {
    resourceName: '$[/myPlugin/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]'

    step 'Transfer Credential',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Transfer Credential.pl").text,
        condition: '$[/javascript "$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/proxyHostName]".length > 0]',
        description: 'If the topazCLIAgent is a proxy agent, then we need to transfer the user name and password from the credential to it (they are temporarily stored in access-locked-down files inside the externalToolsWs directory).',
        errorHandling: 'abortProcedure',
        shell: 'ec-perl'
        
    step 'Download Files (UNIX)',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Download Files (UNIX).sh").text,
        condition: '$[/javascript ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\".slice(-1) == \"x\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"sh \") >= 0 ) ]',
        errorHandling: 'abortProcedure',
        parallel: '1',
        postProcessor: 'postp',
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIWorkspace]'
        
    step 'Download Files (Windows)',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Download Files (Windows).bat").text,
        condition: '$[/javascript ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\" == \"windows\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"cmd \") == 0 ) ]',
        errorHandling: 'abortProcedure',
        parallel: '1',
        postProcessor: 'postp',
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIWorkspace]'
}
  
