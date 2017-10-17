import java.io.File

def procName = 'CreateConfiguration'
procedure procName,
        description: 'Creates a plugin configuration', {

    step 'createConfiguration',
            command: new File(pluginDir, "dsl/procedures/$procName/steps/createConfiguration.pl").text,
            errorHandling: 'abortProcedure',
            exclusiveMode: 'none',
            postProcessor: 'postp',
            releaseMode: 'none',
            shell: 'ec-perl',
            timeLimitUnits: 'minutes'

    step 'createAndAttachCredential',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/createAndAttachCredential.pl").text,
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
        
    property 'ec_stepsWithAttachedCredentials', value: '''[{"procedureName":"Run Total Test", "stepName":"Transfer Credential"},{"procedureName":"Run Total Test", "stepName":"Run Total Test (UNIX)"},{"procedureName":"Run Total Test", "stepName":"Run Total Test (Windows)"},{"procedureName":"Download Files - Topaz 18.2.2-", "stepName":"Transfer Credential"},{"procedureName":"Download Files - Topaz 18.2.2-", "stepName":"Download Files (UNIX)"},{"procedureName":"Download Files - Topaz 18.2.2-", "stepName":"Download Files (Windows)"},{"procedureName":"Download Files - Topaz 18.2.3+", "stepName":"Transfer Credential"},{"procedureName":"Download Files - Topaz 18.2.3+", "stepName":"Download Files (UNIX)"},{"procedureName":"Download Files - Topaz 18.2.3+", "stepName":"Download Files (Windows)"}]'''

}
