import java.io.File

def procName = 'Download Files'
procedure procName, {
    description: 'Use the ISPW CLI to download source code or other component files'
    resourceName: '$[/myPlugin/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]'

    step 'step1',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/step1.bat").text,
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[externalToolsWs]'
}
  
