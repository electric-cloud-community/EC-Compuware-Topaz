use strict;
use warnings;
use ElectricCommander;
# use Data::Dumper;
$| = 1;
my $ec = new ElectricCommander;

# Attach reports
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

# Copy counts to parent step

my $tests = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/tests");
my $errors = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/errors");
my $failures = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/failures");

$tests = $tests->findvalue("//value")->value;
$errors = $errors->findvalue("//value")->value;
$failures = $failures->findvalue("//value")->value;

$ec->setProperty("/myParent/tests", $tests);
$ec->setProperty("/myParent/errors", $errors);
$ec->setProperty("/myParent/failures", $failures);

my $resultPropertySheet = '$[resultPropertySheet]';
if (length($resultPropertySheet) > 0) {
    # Copy counts to property sheet
    $ec->setProperty("$resultPropertySheet/tests", $tests);
    $ec->setProperty("$resultPropertySheet/errors", $errors);
    $ec->setProperty("$resultPropertySheet/failures", $failures);
}