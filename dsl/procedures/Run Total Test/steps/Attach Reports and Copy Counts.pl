use strict;
use warnings;
use ElectricCommander;
use ElectricCommander::PropMod;

use B;
$| = 1;

my $ec = new ElectricCommander;
# Template engine
ElectricCommander::PropMod::loadPerlCodeFromProperty($ec, '/projects/@PLUGIN_NAME@/lib/Text/MicroTemplate');

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

my %reportLinks = ();
foreach my $property (@properties) {
    my $reportName = $property->findvalue("propertyName")->value;
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
        $ec->setProperty("/myJob/artifactsDirectory", {value => "."});
    }

    my $reportLink = "/commander/jobSteps/$[jobStepId]/$reportLocation";
    $reportLinks{$reportName} = $reportLink;
    $ec->setProperty("/myJob/report-urls/$reportName", {value => $reportLink});

    if (length($resultPropertySheet) > 0) {
        $ec->setProperty("$resultPropertySheet/report-urls/$reportName", $reportLink);
    }
}


# Generating HTML report

my $dataForReport = {
    total => $tests,
    failures => $failures,
    abends => $abends,
    errors => $errors,
    reportLinks => \%reportLinks,
};


my $template = $ec->getProperty('/projects/@PLUGIN_NAME@/resources/totalTestReport')->findvalue('//value')->string_value;
my $report = _render_mt(text => $template, render_params => {data => $dataForReport});


# Attach file to job
eval { $ec->getProperty("artifactsDirectory", {"jobId" => "$[jobId]"})};
if ($@) {
    $ec->createProperty("/myJob/artifactsDirectory", {value => "."});
}

my $randomNumber = int rand 99999;
my $totalReportLocation = "totalTestReport_$randomNumber.html";
open my $fh, ">$totalReportLocation" or die "Cannot open $totalReportLocation: $!";
print $fh $report;
close $fh;

my $reportLink = "/commander/jobSteps/$[jobStepId]/$totalReportLocation";
$ec->setProperty("/myJob/report-urls/Topaz for Total Test Report", $reportLink);

eval {
    $ec->setProperty("/myPipelineStageRuntime/ec_summary/Topaz for Total Test Report",
    qq{<html><a href="$reportLink" target="_blank">Link for Report</a></html>});
};

sub _render_mt {
    my (%params) = @_;

    my $template = $params{text};
    my $render_params = $params{render_params};

    my $renderer = Text::MicroTemplate::build_mt($template);

    my $result = eval { $renderer->($render_params)->as_string };
    if ($@) {
        my $message = "Render failed: $@";
        $message .= Dumper(\%params);
        die $message;
    }
    return $result;
}
