use strict;
use warnings;
use ElectricCommander;
# use Data::Dumper;
use B;
$| = 1;

my $ec = new ElectricCommander;

my $platform = '$[/javascript ( ( "$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/hostPlatform]" == "unix" ) || ( '$[/resources/$[/myPlugin/project/ec_plugin_cfgs/$[configurationName]/topazCLIAgent]/shell]'.indexOf("sh ") >= 0 ) ) ? "UNIX" : "Windows"]';

# Copy counts to parent step

my $xpath;
my $tests = 0;
my $errors = 0;
my $failures = 0;
my $abends = 0;

eval {$xpath = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/tests")};
if (!$@) {
    $tests = $xpath->findvalue("//value")->value;
}
eval {$xpath = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/errors")};
if (!$@) {
    $errors = $xpath->findvalue("//value")->value;
}
eval {$xpath = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/failures")};
if (!$@) {
    $failures = $xpath->findvalue("//value")->value;
}
eval {$xpath = $ec->getProperty("/myParent/steps/Retrieve Results and Check for Failures ($platform)/abends")};
if (!$@) {
    $abends = $xpath->findvalue("//value")->value;
}

$ec->setProperty("/myParent/tests", {value => $tests, description => "Count of tests that were run"});
$ec->setProperty("/myParent/errors", {value => $errors, description => "errors = failures + abends"});
$ec->setProperty("/myParent/failures", {value => $failures, description => "Count of tests that were run and failed"});
$ec->setProperty("/myParent/abends", {value => $abends, description => "Count of issues that prevented test(s) from being run"});

my $resultPropertySheet = '$[resultPropertySheet]';
if (length($resultPropertySheet) > 0) {

    # Copy counts to property sheet #### TODO This should check if the properties already exist, and if so do += to accumulate
    $ec->setProperty("$resultPropertySheet/tests", {value => $tests, description => "Count of tests that were run"});
    $ec->setProperty("$resultPropertySheet/errors", {value => $errors, description => "errors = failures + abends"});
    $ec->setProperty("$resultPropertySheet/failures", {value => $failures, description => "Count of tests that were run and failed"});
    $ec->setProperty("$resultPropertySheet/abends", {value => $abends, description => "Count of issues that prevented test(s) from being run"});
}

# Attach reports

my $propertySheet = $ec->getProperties({path => "/myParent/steps/Retrieve Reports ($platform)/reports"});
my @properties = $propertySheet->findnodes("//property");
foreach my $property (@properties) {
    my $reportName = $property->findvalue("propertyName")->value . "-(Run_" . uc(substr(B::hash('$[jobStepId]'),2)) . ")";  # The report name becomes a property name, which has to be unique -- shortening guid to a hash so it looks less ugly
    my $reportLocation = $reportName . ".html";
    my $reportContent = $property->findvalue("value")->value;

    # Attempt to create the file
    open (my $fh, '>', $reportLocation) or die "\nUnable to create file '$reportLocation'\n";

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
    $ec->createProperty("/myJob/report-urls/$reportName", {value => "/commander/jobSteps/$[jobStepId]/$reportLocation"});
    
    if (length($resultPropertySheet) > 0) {
        $ec->createProperty("$resultPropertySheet/report-urls/$reportName", {value => "/commander/jobSteps/$[jobStepId]/$reportLocation"});
    }
}
