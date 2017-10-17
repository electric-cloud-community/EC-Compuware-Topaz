import java.io.File

def procName = 'Run Total Test'
procedure procName, description: 'Use the ISPW CLI to run Total Test test suite(s) or scenario(s)', {
    resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]'

    step 'Transfer Credential',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Transfer Credential.pl").text,
        condition: '$[/javascript "$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/proxyHostName]".length > 0]',
        description: 'If the topazCLIAgent is a proxy agent, then use code copied from ecproxy.pl to make an ssh connection to the same machine that the topazCLIAgent proxies to, and use it to put the user name and password in restricted-access files in a subdirectory called TopazCliWkspc in the externalToolsWs directory',
        errorHandling: 'abortProcedure',
        shell: 'ec-perl'
        
    step 'Run Total Test (UNIX)',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Run Total Test (UNIX).sh").text,
        condition: '$[/javascript ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\" == \"unix\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"sh \") >= 0 ) ]',
        errorHandling: 'abortProcedure',
        parallel: '1',
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[externalToolsWs]'

    step 'Run Total Test (Windows)', 
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Run Total Test (Windows).bat").text,
        condition: '$[/javascript ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\" == \"windows\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"cmd \") == 0 ) ]',
        errorHandling: 'abortProcedure',
        parallel: '1',
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[externalToolsWs]'

    step 'Retrieve Results and Check for Failures (UNIX)', 
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Retrieve Results and Check for Failures (UNIX).sh").text,
        condition: '$[/javascript ( myParent.steps[\'Run Total Test (UNIX)\'].outcome == \'success\' ) && ( ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\" == \"unix\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"sh \") >= 0 ) ) ]',
        errorHandling: 'failProcedure',
        parallel: '1',
        postProcessor: 'postp --loadProperty /myProcedure/extraMatchersResults',
        precondition: '$[/javascript myParent.steps[\'Run Total Test (UNIX)\'].status == \'completed\']',
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[externalToolsWs]'

    step 'Retrieve Results and Check for Failures (Windows)', 
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Retrieve Results and Check for Failures (Windows).bat").text,
        condition: '$[/javascript ( myParent.steps[\'Run Total Test (Windows)\'].outcome == \'success\' ) && ( ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\" == \"windows\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"cmd \") == 0 ) ) ]',
        errorHandling: 'failProcedure',
        parallel: '1',
        postProcessor: 'postp --loadProperty /myProcedure/extraMatchersResults',
        precondition: '$[/javascript myParent.steps[\'Run Total Test (Windows)\'].status == \'completed\']',
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[externalToolsWs]'

    step 'Retrieve Reports (UNIX)', 
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Retrieve Reports (UNIX).sh").text,
        condition: '$[/javascript ( myParent.steps[\'Run Total Test (UNIX)\'].outcome == \'success\' ) && ( ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\" == \"unix\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"sh \") >= 0 ) ) ]',
        errorHandling: 'failProcedure',
        parallel: '1',
        postProcessor: 'postp --loadProperty /myProcedure/extraMatchersReports',
        precondition: '$[/javascript myParent.steps[\'Run Total Test (UNIX)\'].status == \'completed\']',
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[externalToolsWs]'

    step 'Retrieve Reports (Windows)', 
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Retrieve Reports (Windows).bat").text,
        condition: '$[/javascript ( myParent.steps[\'Run Total Test (Windows)\'].outcome == \'success\' ) && ( ( \"$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]\" == \"windows\" ) || ( \'$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]\'.indexOf(\"cmd \") == 0 ) ) ]',
        errorHandling: 'failProcedure',
        parallel: '1',
        postProcessor: 'postp --loadProperty /myProcedure/extraMatchersReports',
        precondition: '$[/javascript myParent.steps[\'Run Total Test (Windows)\'].status == \'completed\']',
        resourceName: '$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]',
        workingDirectory: '$[externalToolsWs]'

    step 'Attach Reports (Windows)', 
        command: new File(pluginDir, "dsl/procedures/$procName/steps/Attach Reports.pl").text,
        errorHandling: 'failProcedure',
        shell: 'ec-perl'

    property 'extraMatchersResults', value: '''push (@::gMatchers, 
        {
            id      => "testCaseTag",
            pattern => q{<test[Cc]ase[> ]},
            action  => q{
                  incValue("tests");
                        } 
        },
        {
            id      => "failureTag",
            pattern => q{<failure[> ]},
            action  => q{
                  incValue("errors"); incValue("failures"); diagnostic("failureTag", "error", backTo(q{<test[Cc]ase[> ]}, -1), forwardTo(q{</test[Cc]ase[> ]}, 1))
                        } 
        },
        {
            id      => "errorTag",
            pattern => q{<error[> ]},
            action  => q{
                  incValue("errors"); diagnostic("errorTag", "error", backTo(q{<test[Cc]ase[> ]}, -1), forwardTo(q{</test[Cc]ase[> ]}, 1))
                        } 
        },
     );'''

    property 'extraMatchersReports', value: '''$::gReportStarted = 0;
undef $::gReportTitle;
$::gReportContents = "";
push (@::gMatchers, 
        {
            id      => "report",
            pattern => q{<title>Unit Test.\\.temp.([^<]+)</title>},
            action  => q{
                  $::gReportTitle = $1;                  
                             } 
        },
        {
            id      => "anyLine",
            pattern => q{(.*)},
            action  => q{
                  my $line = $1;
                  if ($line =~ /<html>/) {
                      $::gReportStarted = 1;
                  }
                  if ($::gReportStarted) {
                      $::gReportContents .= $line."\n";
                  }
                  if (($line =~ m|</html>(?!")|) && defined($::gReportTitle)) {
                      setProperty("reports/".$::gReportTitle, $::gReportContents);
                      incValue("reportCount");
                      $::gReportStarted = 0;
                      undef $::gReportTitle;
                      $::gReportContents = "";
                  }
                             } 
        },
     );'''

}