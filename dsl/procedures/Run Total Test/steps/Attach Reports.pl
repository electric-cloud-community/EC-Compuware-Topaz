use strict;
use warnings;
use ElectricCommander;
$| = 1;
my $ec = new ElectricCommander;

my $propertySheet = $ec->getProperties({path => "/myParent/steps/Retrieve Reports ($[/javascript ( ( "$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]" == "unix" ) || ( '$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]'.indexOf("sh ") >= 0 ) ) ? 'UNIX' : 'Windows'])/reports"});
my @properties = $propertySheet->findnodes("//property");
foreach my $property (@properties) {
    my $reportName = $property->findvalue("propertyName")->value . "_($[jobStepId]).html";
    my $reportContent= $property->findvalue("value")->value;

    # Attempt to create the file
    open (my $fh, '>', $reportName) or die "\nUnable to create file '$reportName'\n";

    # Write html content to the file.
    print $fh $reportContent;

    # Close the file.
    close $fh;

    # Attach file to job
    my $xp;
    eval {$xp = $ec->getProperty("artifactsDirectory", {"jobId" => "$[jobId]"})};
    if ($@) {
        $ec->createProperty("/myJob/artifactsDirectory", {value => "."});
    }
    $ec->createProperty("/myJob/report-urls/$reportName", {value => "/commander/jobSteps/$[jobStepId]/$reportName"});
}