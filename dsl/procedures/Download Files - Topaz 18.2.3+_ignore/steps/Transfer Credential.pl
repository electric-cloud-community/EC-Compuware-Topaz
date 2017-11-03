use strict 'vars';
use strict 'subs';
use warnings;

use Net::SSH2;
use File::Basename;
use File::Temp;
use IO::Socket;
use XML::XPath;
use ElectricCommander;
$| = 1;
my $ec = new ElectricCommander;

#############################################
#
# Utility subroutines copied from ecproxy.pl
#

my $gBanner = "Based on Electric Cloud ElectricCommander Agent Proxy "
    . "Copyright (C) 2007-" . (1900 + (localtime())[5])
    . " Electric Cloud, Inc.\n"
    . "All rights reserved.\n";

my $gDebugFile = "";
if (exists($ENV{ECPROXY_DEBUGFILE})) {
    $gDebugFile = $ENV{ECPROXY_DEBUGFILE};
    if (exists($ENV{COMMANDER_JOBSTEPID})) {
        $gDebugFile .= $ENV{COMMANDER_JOBSTEPID};
    }
}

my %gProtocolConfig = ();

####################### Useful Helper Functions #########################

# ------------------------------------------------------------------------
# mesg
#
#     Log a message to the debug log, if the gDebugFile variable is set.
#
# Arguments:
#     msg - The message to log.
# ------------------------------------------------------------------------
sub mesg($) {
    my ($msg) = @_;
    if ($gDebugFile ne "") {
        # Sometimes, we open the debug file but the file-handle gets closed
        # from underneath us (maybe when the script is dying?)  printf will
        # issue a warning that we don't care about in that case.  Disable
        # warnings in this block to avoid that warning.

        no warnings;
        open DBGFILE, ">> $gDebugFile" || return;
        my ($sec, $min, $hour) = (localtime)[0..2];
        printf DBGFILE "[%02d:%02d:%02d] %s\n", $hour, $min, $sec, $msg;
        close DBGFILE;
    }
};

# ------------------------------------------------------------------------
# loadFile
#
#      Loads the given file, which contains Perl code to evaluate
#      to customize the behavior of ecproxy.
#
# Arguments:
#      fileName - Name / path to file.
# ------------------------------------------------------------------------

sub loadFile($) {
    my ($fileName) = @_;
    if (! -r $fileName) {
        die("Customization file '$fileName' does not exist or is not " .
            "readable.\n");
    }

    # Read the file.
    my $result = "";
    my $buffer;
    open(CUSTOM_FILE, "< $fileName") or die("Couldn't open customization file '$fileName': $!");
    while (read(CUSTOM_FILE, $buffer, 4096)) {
        $result .= $buffer;
    }
    close CUSTOM_FILE;

    # Load the contents...
    eval $result or die($@);
}

# ------------------------------------------------------------------------
# isPortValid
#
#      Determins if the given port is a legal value.
#
# Arguments:
#      port - Port number to evaluate.
# ------------------------------------------------------------------------

sub isPortValid($) {
    my $port = shift;
    return ($port && $port =~ /^[0-9]+$/ && $port > 0);
}

# ------------------------------------------------------------------------
# setSSHKeyFiles
#
#      Set the paths to the public and private key files that ssh will use to
#      authenticate with the proxy target.
#
# Arguments:
#      publicKeyFile - Path to public key file.
#      privKeyFile   - Path to private key file.
# ------------------------------------------------------------------------

sub setSSHKeyFiles($$) {
    my ($pubKeyFile, $privKeyFile) = @_;

    $gProtocolConfig{pubKeyFile} = $pubKeyFile;
    $gProtocolConfig{privKeyFile} = $privKeyFile;
}

# ------------------------------------------------------------------------
# setSSHPasswordCredential
#
#      Set the password to authenticate with the proxy target.
#
# Arguments:
#      passwordCredential
# ------------------------------------------------------------------------

sub setSSHPasswordCredential($) {
    my ($passwordCredential) = @_;
    my $password = returnPasswordFromCredential($passwordCredential,$ec);

    $gProtocolConfig{password} = $password;
}

# ------------------------------------------------------------------------
# setSSHPassphraseCredential
#
#      Set the passphrase protecting the ssh private key.
#
# Arguments:
#      passphraseCredential
# ------------------------------------------------------------------------

sub setSSHPassphraseCredential($) {
    my ($passwordCredential) = @_;
    my $passphrase = returnPasswordFromCredential($passwordCredential,$ec);

    $gProtocolConfig{passphrase} = $passphrase;
}

# ------------------------------------------------------------------------
# returnPasswordFromCredential
#
#      Performs getFullCredential on the credential specified and returns the password
#
# Arguments:
#      credential - path to a credential
#      ec - an ElectricCommander object
# ------------------------------------------------------------------------
sub returnPasswordFromCredential($$){
  my($credential,$ec) = @_;

  return $ec->getFullCredential("$credential", {value=>'password'})->findvalue('//password')->value();
}

# ------------------------------------------------------------------------
# setSSHUser
#
#      Set the name of the user to authenticate with the proxy target.
#
# Arguments:
#      userName
# ------------------------------------------------------------------------

sub setSSHUser($) {
    my ($userName) = @_;

    $gProtocolConfig{userName} = $userName;
}

####################### SSH Operation Implementations #########################

# ------------------------------------------------------------------------
# ssh_getDefaultTargetPort
#
#      Returns the default target port for this protocol.
#
# Arguments:
#      None
# ------------------------------------------------------------------------

sub ssh_getDefaultTargetPort() {
    return 22;
}

# ------------------------------------------------------------------------
# ssh_connect
#
#      Opens a connection to the proxy target via ssh.
#
# Arguments:
#      host   - Name or IP address of the proxy target.
#      port   - (optional) Port to connect to.  Defaults to 22.
# ------------------------------------------------------------------------

sub ssh_connect($;$) {
    my ($host, $port) = @_;
    $port = ssh_getDefaultTargetPort() unless isPortValid($port);

    my $pubKeyFile = $gProtocolConfig{pubKeyFile} ||
        $ENV{ECPROXY_SSH_PUBKEYFILE};
    my $privKeyFile = $gProtocolConfig{privKeyFile} ||
        $ENV{ECPROXY_SSH_PRIVKEYFILE};
    my $userName = $gProtocolConfig{userName} ||
        $ENV{ECPROXY_SSH_USER};
    my $password = $gProtocolConfig{password};
    my $passphrase = $gProtocolConfig{passphrase};

    if ($^O =~ /MSWin/) {
        # Figure out the user to ssh as by looking in the following places:
        # 1. gProtocolConfig{userName}, set by setSSHUser / ECPROXY_SSH_USER.
        # 2. the USER env var.
        # 3. the USERNAME env var.

        $userName ||= $ENV{USER} || $ENV{USERNAME};
        $userName || die "ssh_connect: Couldn't determine current username: " .
            "neither USER nor USERNAME environment variables are " .
            "set\n";
    } else {
        $userName = getpwuid($<) unless defined($userName);
        $userName || die "ssh_connect: Couldn't determine current username " .
            "from uid $<: $!\n";

        if (!$pubKeyFile) {

            # There are a couple of different commonly used names for
            # key-files.  DSA key-files are often called id_dsa / id_dsa.pub.
            # RSA key-files are often called id_rsa / id_rsa.pub.  Another
            # convention is to name them identity / identity.pub.  So check
            # for all three and pick the first matching set.

            foreach my $fname ("id_dsa", "id_rsa", "identity") {
                my $fnameFullPath = $ENV{HOME} . "/.ssh/" . $fname;
                if (-r $fnameFullPath) {
                    $pubKeyFile = $fnameFullPath . ".pub";
                    $privKeyFile ||= $fnameFullPath;
                    last;
                }
            }
        }
    }

    # If the password is specified skip key file sanity checks
    if(!$password) {
        # Be sure that pubKeyFile, and privKeyFile are defined and that the two
        # files actually exist.  Error out otherwise.

        $pubKeyFile || die "ssh_connect: Public key file must be specified; use " .
                "setSSHKeyFiles\n";

        if (! -r $pubKeyFile) {
            die "ssh_connect: Public key file '$pubKeyFile' does not exist or " .
                "is not readable\n";
        }

        $privKeyFile || die "ssh_connect: Private key file must be specified; " .
            "use setSSHKeyFiles\n";

        if (! -r $privKeyFile) {
            die "ssh_connect: Private key file '$privKeyFile' does not exist " .
                "or is not readable\n";
        }
    }

    # Create $gProtocolConfig{numSessions} ssh sessions.
    $gProtocolConfig{numSessions} ||= "1";

    my $context = {};
    for (my $ind = 1; $ind <= $gProtocolConfig{numSessions}; $ind++) {
        # Ok, try and connect...

        my $ssh2 = Net::SSH2->new();
        my $result = eval {
            $ssh2->connect($host, $port);
        };

        if (!$result) {
            die "ssh_connect: Error connecting to $host:$port: $!\n";
        }

        #$ssh2->debug(1);
        if ($password){
               mesg("ssh_connect: Creating session $ind: Connecting to " .
               "$host:$port with userName=$userName password=[PROTECTED]");

            $ssh2->auth_password($userName, $password);
            if(!$ssh2->auth_ok){
                my $errorString = $ssh2->error();

                my $msg =
                    "ssh_connect: user/pass authentication failed for $userName";

                mesg($msg);
                die $msg . "\n";
            }
        } else{
            mesg("ssh_connect: Creating session $ind: Connecting to " .
               "$host:$port with userName=$userName pubKeyFile=$pubKeyFile " .
               "privKeyFile=$privKeyFile");

            # libssh2 has a bug where sometimes key-authentication fails even
            # though the keyfiles are perfectly valid.  Retry upto three more times
            # with a little sleep in between before giving up.

            my $attemptCount = 1;
            my $maxAttempts = 4;
            my $errorString;
            for (; $attemptCount <= $maxAttempts &&
                 !$ssh2->auth_publickey($userName, $pubKeyFile, $privKeyFile, $passphrase);
                 $attemptCount++) {
                $errorString = ($ssh2->error())[2];
                mesg("Authentication attempt $attemptCount failed with error: " .
                     "$errorString");
                sleep 2;
            }

            if ($attemptCount == $maxAttempts+1) {
                my $msg =
                    "ssh_connect: Key authentication failed for $userName using " .
                    "the following key files:\n" .
                    "public key file: $pubKeyFile\n" .
                    "private key file: $privKeyFile\n" .
                    "error detail: $errorString";

                mesg($msg);
                die $msg . "\n";
            }
        }

        # Success! Save off the session handle.
        push(@{$context->{sshHandles}}, $ssh2);
        mesg("ssh_connect: Connection succeeded!");
    }

    # Ok, we've created all of our sessions.  If we are in "multi-session"
    # mode, we want to set up our context like this:
    # $context->{sshHandles}[0] and [1] will be used for uploading the
    # command file and wrapper script file to the proxy target.
    # $context->{channels}[0] and [1] will be based off of
    # $context->{sshHandles}[2] and [3], respectively, and will be used
    # for running the wrapper script and running a cleanup command.
    #
    # If we're in "single-session-multi-channel" mode, we want to set up
    # the context like this:
    # $context->{sshHandles}[0] will be used for *both* uploads.
    # $context->{channels}[0] and [1] are based off of the one session.
    #
    # To make the rest of the ssh operations not worry about this distinction,
    # we make the single-session case look like the multi-session case by
    # inserting the one session twice in sshHandles.

    if ($gProtocolConfig{numSessions} == 1) {
        my $session = $context->{sshHandles}[0];
        push(@{$context->{sshHandles}}, $session);
        push(@{$context->{channels}}, $session->channel(),
             $session->channel());
    } else {
        push(@{$context->{channels}}, $context->{sshHandles}[2]->channel(),
             $context->{sshHandles}[3]->channel());
    }
    return $context;
}

# ------------------------------------------------------------------------
# ssh_runCommand
#
#      Runs the given command-line on the proxy target and streams the
#      result to stdout.
#
# Arguments:
#      context       - Context object that contains connection info.
#      cmdLine       - command-line to execute.
# ------------------------------------------------------------------------

sub ssh_runCommand($$) {
    my ($context, $cmdLine) = @_;

    mesg("About to run '$cmdLine' on proxy target");

    my $channel = shift(@{$context->{channels}});
    $channel->blocking(0);
    if ($gProtocolConfig{usePty}) {
        $channel->pty('tty');
    }
    $channel->ext_data('merge');
    $channel->exec($cmdLine);
    my $buf;
    while (!$channel->eof()) {
        if (defined($channel->read($buf, 4096))) {
            print $buf;
        } else {
            # We got no data; try again in a second.
            sleep 1;
        }
    }

    return $channel->exit_status();
}

#
# End of utility subroutines copied from ecproxy.pl
#
####################################################

# Include any special instructions for how to connect to the proxy's remote machine
#
# e.g.:
#
# loadFile("custom.pl")
# setSSHKeyFiles('c:\foo\pub.key', 'c:\foo\priv.key')
# setSSHUser('elccld1');
# $gProtocolConfig{password} = 'BigSecret';

$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/proxyCustomization]

# Get the credential to transfer
my $credential = $ec->getFullCredential("$[configurationName]");
my $userName = $credential ->find("//userName");
my $password = $credential ->find("//password");

# SSH across and save the credential as a protected file

# What to do on the remote machine:
# Securely store the remote password in an access-controlled file in the working directory on the proxied machine, so it never appears on the command line

my $command;
if ( $[/javascript ( ( "$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]" == "unix" ) || ( '$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]'.indexOf("sh ") >= 0 ) ) ? '1' : '0' ] ) {
    $command = <<_EOUNIX_
cd '$[/javascript myPlugin.project.ec_plugin_cfgs.$[configurationName].topazCLIWorkspace.replace(/\\/g, "\\\\\\\\")]'
touch eccu eccp
chmod 600 eccu eccu
builtin echo "$userName" > eccu
builtin echo "$password" > eccp
chmod 400 eccu eccp
_EOUNIX_
} elsif ( $[/javascript ( ( '$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]'.indexOf("cmd ") == 0 ) && ( '$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]'.indexOf(' "{0}.cmd"') == '$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]'.length - 10 ) ) ? '1' : '0' ] ) { # Expecting something like 'cmd /q /c "{0}.cmd"'
    $command = <<_EOWINDOWS_
cmd /q <<_EOCMD_
cd "$[/javascript myPlugin.project.ec_plugin_cfgs.$[configurationName].topazCLIWorkspace.replace(/\\/g, '\\\\\\\\')]"
copy /Y NUL eccu
copy /Y NUL eccp
:: attrib -A +I eccu TODO Figure out why these kill the script
:: attrib -A +I eccp
icacls eccu /inheritance:r /grant:r *S-1-3-4:F /grant:r *S-1-5-32-544:(d)
icacls eccp /inheritance:r /grant:r *S-1-3-4:F /grant:r *S-1-5-32-544:(d)
echo $userName> eccu
echo $password> eccp
:: attrib +R +S +H eccu
:: attrib +R +S +H eccp
_EOCMD_
_EOWINDOWS_
} else {
    die <<_EODIE_

Don't know how to handle $[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent] proxy agent shell value '$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]'

_EODIE_
}

# Open an ssh connection
my $host = "$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostName]";
my $port = "$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/port]";

my $cntxt = ssh_connect($host, $port);

# Run the command

my $status = ssh_runCommand($cntxt, $command);
exit $status;
