package WebGUI::Definition::Meta::Property;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2009 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use 5.010;
use Moose;
use namespace::autoclean;
no warnings qw(uninitialized);

our $VERSION = '0.0.1';

extends 'Moose::Meta::Attribute';

has 'form' => (
    is  => 'ro',
);

1;

