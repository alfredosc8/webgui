package WebGUI::Asset::Sku::EMSBadge;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2008 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use Tie::IxHash;
use base 'WebGUI::Asset::Sku';
use JSON;
use WebGUI::HTMLForm;
use WebGUI::International;


=head1 NAME

Package WebGUI::Asset::Sku::EMSBadge

=head1 DESCRIPTION

A badge for the Event Manager. Badges allow you into the convention.

=head1 SYNOPSIS

use WebGUI::Asset::Sku::EMSBadge;

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------
sub addToCart {
	my ($self, $badgeInfo) = @_;
	$badgeInfo->{badgeId} = "new";
	$badgeInfo->{badgeAssetId} = $self->getId;
	$badgeInfo->{emsAssetId} = $self->getParent->getId;
	my $badgeId = $self->session->db->setRow("EMSRegistrant","badgeId", $badgeInfo);
	$self->SUPER::addToCart({badgeId=>$badgeId});
}

#-------------------------------------------------------------------
sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my %properties;
	tie %properties, 'Tie::IxHash';
	my $i18n = WebGUI::International->new($session, "Asset_EventManagementSystem");
	%properties = (
		price => {
			tab             => "commerce",
			fieldType       => "float",
			defaultValue    => 0.00,
			label           => $i18n->get("price"),
			hoverHelp       => $i18n->get("price help"),
			},
		seatsAvailable => {
			tab             => "properties",
			fieldType       => "integer",
			defaultValue    => 100,
			label           => $i18n->get("seats available"),
			hoverHelp       => $i18n->get("seats available help"),
			},
	    );
	push(@{$definition}, {
		assetName           => $i18n->get('ems badge'),
		icon                => 'EMSBadge.gif',
		autoGenerateForms   => 1,
		tableName           => 'EMSBadge',
		className           => 'WebGUI::Asset::Sku::EMSBadge',
		properties          => \%properties
	    });
	return $class->SUPER::definition($session, $definition);
}


#-------------------------------------------------------------------
sub getConfiguredTitle {
    my $self = shift;
	my $name = $self->session->db->getScalar("select name from EMSRegistrant where badgeId=?",[$self->getOptions->{badgeId}]);
    return $self->getTitle." (".$name.")";
}


#-------------------------------------------------------------------
sub getMaxAllowedInCart {
	return 1;
}

#-------------------------------------------------------------------
sub getPrice {
    my $self = shift;
    return $self->get("price");
}

#-------------------------------------------------------------------
sub getQuantityAvailable {
	my $self = shift;
	my $seatsTaken = $self->session->db->quickScalar("select count(*) from EMSRegistrant where badgeAssetId=?",[$self->getId]);
    return $self->get("seatsAvailable") - $seatsTaken;
}

#-------------------------------------------------------------------
sub onCompletePurchase {
	my ($self, $item) = @_;
	my $badgeInfo = $self->getOptions;
	$badgeInfo->{purchaseComplete} = 1;
	$badgeInfo->{userId} = $self->session->user->userId; # they have to be logged in at this point
	$self->session->db->setRow("EMSRegistrant","badgeId", $badgeInfo);
	return undef;
}

#-------------------------------------------------------------------
sub onRemoveFromCart {
	my ($self, $item) = @_;
	my $badgeId = $self->getOptions->{badgeId};
	foreach my $cartitem (@{$item->cart->getItems()}) {
		if (isIn((ref $cartitem), qw(WebGUI::Asset::Sku::EMSTicket WebGUI::Asset::Sku::EMSRibbon WebGUI::Asset::Sku::EMSToken))) {
			if ($cartitem->getSku->getOptions->{badgeId} eq $badgeId) {
				$cartitem->remove;
			}
		}
	}
	$self->session->db->deleteRow('EMSRegistrant','badgeId',$badgeId);
}

#-------------------------------------------------------------------
sub purge {
	my $self = shift;
	$self->session->db->write("delete from EMSRegistrant where badgeAssetId=?",[$self->getId]);
	$self->SUPER::purge;
}

#-------------------------------------------------------------------
sub view {
	my ($self) = @_;
	
	my $error = $self->{_errorMessage};
	my $i18n = WebGUI::International->new($self->session, "Asset_EventManagementSystem");
	my $form = $self->session->form;
	
	# build the form to allow the user to choose from their address book
	my $book = WebGUI::HTMLForm->new($self->session, action=>$self->getUrl);
	$book->hidden(name=>"shop", value=>"address");
	$book->hidden(name=>"method", value=>"view");
	$book->hidden(name=>"callback", value=>JSON::to_json({
		url		=> $self->getUrl,
		}));
	$book->submit(value=>$i18n->get("populate from address book"));
	
	# instanciate address
	my $address = WebGUI::Shop::Address->new($self->session, $form->get("addressId")) if ($form->get("addressId"));
	
	# build the form that the user needs to fill out with badge holder information
	my $info = WebGUI::HTMLForm->new($self->session, action=>$self->getUrl);
	$info->hidden(name=>"func", value=>"addToCart");
	$info->text(
		name			=> 'name',
		defaultValue	=> (defined $address) ? $address->get("name") : $form->get('name'),
		label			=> $i18n->get('name','Shop'),
		);
	$info->text(
		name			=> 'organization',
		defaultValue	=> $form->get("organization"),
		label			=> $i18n->get('organization'),
		);
	$info->text(
		name			=> 'address1',
		defaultValue	=> (defined $address) ? $address->get("address1") : $form->get('address1'),
		label			=> $i18n->get('address','Shop'),		
		);
	$info->text(
		name			=> 'address2',
		defaultValue	=> (defined $address) ? $address->get("address2") : $form->get('address2'),
		);
	$info->text(
		name			=> 'address3',
		defaultValue	=> (defined $address) ? $address->get("address3") : $form->get('address3'),
		);
	$info->text(
		name			=> 'city',
		defaultValue	=> (defined $address) ? $address->get("city") : $form->get('city'),
		label			=> $i18n->get('city','Shop'),		
		);
	$info->text(
		name			=> 'state',
		defaultValue	=> (defined $address) ? $address->get("state") : $form->get('state'),
		label			=> $i18n->get('state','Shop'),		
		);
	$info->zipcode(
		name			=> 'zipcode',
		defaultValue	=> (defined $address) ? $address->get("code") : $form->get('zipcode','zipcode'),
		label			=> $i18n->get('code','Shop'),		
		);
	$info->country(
		name			=> 'country',
		defaultValue	=> (defined $address) ? $address->get("country") : ($form->get('country') || 'United States'),
		label			=> $i18n->get('country','Shop'),		
		);
	$info->phone(
		name			=> 'phoneNumber',
		defaultValue	=> (defined $address) ? $address->get("phoneNumber") : $form->get("phone","phone"),
		label			=> $i18n->get('phone number','Shop'),		
		);
	$info->email(
		name			=> 'email',
		label			=> $i18n->get('email address'),
		defaultValue	=> $form->get("email","email")
		);
	$info->submit(value=>$i18n->get('add to cart','Shop'));
	
	# render the page;
	my $output = '<h1>'.$self->getTitle.'</h1>'
		.'<p>'.$self->get('description').'</p>'
		.'<h2>'.$i18n->get("badge holder information").'</h2>'
		.$book->print;
	if ($error ne "") {
		$output .= '<p><b>'.$error.'</b></p>';
	}
	$output .= $info->print;
	return $output;
}


#-------------------------------------------------------------------
sub www_addToCart {
	my ($self) = @_;
	return $self->session->privilege->noAccess() unless $self->getParent->canView;
	
	# gather badge info
	my $form = $self->session->form;
	my %badgeInfo = ();
	foreach my $field (qw(name address1 address2 address3 city state organization)) {
		$badgeInfo{$field} = $form->get($field, "text");
	}
	$badgeInfo{'phoneNumber'} = $form->get('phoneNumber', 'phone');
	$badgeInfo{'email'} = $form->get('email', 'email');
	$badgeInfo{'country'} = $form->get('country', 'country');
	$badgeInfo{'zipcode'} = $form->get('zipcode', 'zipcode');
	

	# check for required fields
	my $error = "";
	my $i18n = WebGUI::International->new($self->session, 'Asset_EventManagementSystem');
	if ($badgeInfo{name} eq "") {
		$error =  sprintf $i18n->get('is required'), $i18n->get('name','Shop');
	}
	
	# return them back to the previous screen if they messed up
	if ($error) {
		$self->{_errorMessage} = $error;
		return $self->www_view($error);
	}
	
	# add it to the cart
	$self->addToCart(\%badgeInfo);
	return $self->getParent->www_view;
}

1;
