package WebGUI::Macro;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2002 Plain Black LLC.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut


use strict qw(vars subs);
use WebGUI::ErrorHandler;
use WebGUI::Session;


=head1 NAME

 Package WebGUI::Macro

=head1 SYNOPSIS

 use WebGUI::Macro;
 @array = WebGUI::Macro::getParams($parameterString);
 $html = WebGUI::Macro::process($html);

=head1 DESCRIPTION

 This package is the interface to the WebGUI macro system.

 NOTE: This entire system is likely to be replaced in the near future. 
 It has served WebGUI well since the very beginning but lacks the 
 speed and flexibility that WebGUI users will require in the future.

=head1 METHODS

 These functions are available from this package:

=cut



#-------------------------------------------------------------------

=head2 getParams ( parameterString )

 A simple, but error prone mechanism for getting a prameter list from a string. Returns an array of parameters.

=item parameterString

 A string containing a comma separated list of paramenters.

=cut

sub getParams {
        my ($data, @param);
        $data = $_[0];
        push(@param, $+) while $data =~ m {
                "([^\"\\]*(?:\\.[^\"\\]*)*)",?
                |       ([^,]+),?
                |       ,
        }gx;
        push(@param, undef) if substr($data,-1,1) eq ',';
	return @param;
}

#-------------------------------------------------------------------

=head2 process ( html )

 Runs all the WebGUI macros to and replaces them in the HTML with their output.

=item html

 A string of HTML to be processed.

=cut

sub process {
        my ($macro, $cmd, $output);
	$output = $_[0];
        foreach $macro (keys %{$session{macro}}) {
		$cmd = "WebGUI::Macro::".$macro."::process";
		$output = eval{&$cmd($output)};
		WebGUI::ErrorHandler::fatalError("Processing failed on macro: $macro: ".$@) if($@);
        }
	return $output;
}

1;

