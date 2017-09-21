import java.io.File

def procName = 'Run Total Test'
procedure procName, {
    description: 'Use the ISPW CLI to run Total Test test suite(s) or scenario(s)'
    resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]'

    step 'step1',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/step1.bat").text,
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[externalToolsWs]'


}