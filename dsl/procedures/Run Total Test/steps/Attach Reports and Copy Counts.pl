use strict;
use warnings;
use ElectricCommander;
# use Data::Dumper;
$| = 1;
my $ec = new ElectricCommander;

my $platform = '$[/javascript ( ( "$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]" == "unix" ) || ( '$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]'.indexOf("sh ") >= 0 ) ) ? "UNIX" : "Windows"]';
my $propertySheet = $ec->getProperties({path => "/myParent/steps/Retrieve Reports ($platform)/reports"});
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

my $tests = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/tests");
$ec->setProperty("/myParent/tests", $tests->findvalue("//value")->value);
my $errors = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/errors");
$ec->setProperty("/myParent/errors", $errors->findvalue("//value")->value);
my $failures = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/failures");
$ec->setProperty("/myParent/failures", $failures->findvalue("//value")->value);