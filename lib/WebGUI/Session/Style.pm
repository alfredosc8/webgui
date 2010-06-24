package WebGUI::Session::Style;

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


use strict;
use WebGUI::International;
use WebGUI::Macro;
require WebGUI::Asset;
BEGIN { eval { require WebGUI; WebGUI->import } }
use HTML::Entities ();
use Scalar::Util qw(weaken);

=head1 NAME

Package WebGUI::Session::Style

=head1 DESCRIPTION

This package contains utility methods for WebGUI's style system.

=head1 SYNOPSIS

 use WebGUI::Session::Style;
 $style = WebGUI::Session::Style->new($session);

 $html = $style->generateAdditionalHeadTags();
 $html = $style->process($content);

 $session = $style->session;
 
 $style->makePrintable(1);
 $style->setLink($url,\%params);
 $style->setMeta(\%params);
 $style->setRawHeadTags($html);
 $style->setScript($url, \%params);
 $style->useEmptyStyle(1);

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

sub _generateAdditionalTags {
	my $var = shift;
	return sub {
		my $self = shift;
		my $tags = $self->{$var};
		delete $self->{$var};
		WebGUI::Macro::process($self->session,\$tags);
		return $tags;
	};
}

#-------------------------------------------------------------------

=head2 generateAdditionalBodyTags ( )

Creates tags that were set using setScript (if inBody was true) and setRawBodyTags.
Macros are processed in the tags if processed by this method.

=cut

BEGIN { *generateAdditionalBodyTags = _generateAdditionalTags('_rawBody') }


#-------------------------------------------------------------------

=head2 generateAdditionalHeadTags ( )

Creates tags that were set using setLink, setMeta, setScript, extraHeadTags, and setRawHeadTags.
Macros are processed in the tags if processed by this method.

=cut

BEGIN { *generateAdditionalHeadTags = _generateAdditionalTags('_raw') }

#-------------------------------------------------------------------

=head2 makePrintable ( boolean ) 

Tells the system to use the make printable style instead of the normal style.

=head3 boolean

If set to 1 then the printable style will be used, otherwise the regular style will be used.

=cut

sub makePrintable {
	my $self = shift;
	$self->{_makePrintable} = shift;
}

#-------------------------------------------------------------------

=head2 useMobileStyle

Returns a true value if we are on a mobile display.

=cut

sub useMobileStyle {
    my $self = shift;
    my $session = $self->session;
    my $scratchCheck = $session->scratch->get('useMobileStyle');
    if (defined $scratchCheck) {
        return $scratchCheck;
    }
    if (exists $self->{_useMobileStyle}) {
        return $self->{_useMobileStyle};
    }

    if (! $session->setting->get('useMobileStyle')) {
        return $self->{_useMobileStyle} = 0;
    }
    my $ua = $session->env->get('HTTP_USER_AGENT');
    for my $mobileUA (@{ $self->session->config->get('mobileUserAgents') }) {
        if ($ua =~ m/$mobileUA/) {
            return $self->{_useMobileStyle} = 1;
        }
    }
    return $self->{_useMobileStyle} = 0;
}

#-------------------------------------------------------------------

=head2 setMobileStyle

Sets whether the mobile style should be used for this session.

=cut

sub setMobileStyle {
    my $self = shift;
    my $enableMobile = shift;
    $self->session->scratch->set('useMobileStyle', $enableMobile);
    return $enableMobile;
}

#-------------------------------------------------------------------

=head2 new ( session ) 

Constructor.

=head3 session

A reference to the current session.

=cut

sub new {
	my $class = shift;
	my $session = shift;
    my $self = bless { _session => $session}, $class;
    weaken $self->{_session};
    return $self;
}

#-------------------------------------------------------------------

=head2 process ( content, templateId )

Returns a parsed style with content based upon the current WebGUI session information.
Sets the C<sent> method/flag to be true so that subsequent head data is processed
right away.

=head3 content

The content to be parsed into the style. Usually generated by WebGUI::Page::generate().

=head3 templateId

The unique identifier for the template to retrieve.
If $style->useEmptyStyle has been set, then the empty style
templateId will be used over templateId.  If personalStyleId
is set in $session->scratch, then that id will be used over the
other two.  Finally, if $style->makePrintable has been called,
process will try to find a template for making the output printable
from $style->printableStyleId, from $session->asset or from any of
$session->asset's ancestors.

=cut

sub process {
	my $self    = shift;
    my $session = $self->session;
	my %var;
	$var{'body.content'} = shift;
	my $templateId = shift;
	if ($self->{_makePrintable} && $self->session->asset) {
		$templateId = $self->{_printableStyleId} || $session->asset->get("printableStyleTemplateId");
		my $currAsset = $session->asset;
		my $rootAssetId = WebGUI::Asset->getRoot($session)->getId;
		TEMPLATE: until ($templateId) {
			# some assets don't have this property.  But at least one ancestor should....
			$currAsset  = $currAsset->getParent;
			$templateId = $currAsset->get("printableStyleTemplateId");
			last TEMPLATE if $currAsset->getId eq $rootAssetId;
		}
	} elsif ($session->scratch->get("personalStyleId") ne "") {
		$templateId = $session->scratch->get("personalStyleId");
	} elsif ($self->{_useEmptyStyle}) {
		$templateId = 'PBtmpl0000000000000132';
	}
$var{'head.tags'} = '
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="generator" content="WebGUI '.$WebGUI::VERSION.'" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<script type="text/javascript">
function getWebguiProperty (propName) {
var props = new Array();
props["extrasURL"] = "'     . $session->url->extras().'";
props["pageURL"] = "'       . $session->url->page(undef, undef, 1).'";
props["firstDayOfWeek"] = "'. $session->user->get('firstDayOfWeek').'";
return props[propName];
}
</script>
' . $self->session->setting->get('globalHeadTags') . '
<!--morehead-->
';

if ($self->session->user->isRegistered || $self->session->setting->get("preventProxyCache")) {
	# This "triple incantation" panders to the delicate tastes of various browsers for reliable cache suppression.
	$var{'head.tags'} .= '
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-cache, must-revalidate, max-age=0, private" />
<meta http-equiv="Expires" content="0" />
';
	$self->session->http->setCacheControl("none");
} else {
	$var{'head.tags'} .= '<meta http-equiv="Cache-Control" content="must-revalidate" />'
}


    # TODO: Figure out if user is still in the admin console
    if ( $session->asset ) {
        my $assetDef    = { 
            assetId     => $session->asset->getId,
            title       => $session->asset->getTitle,
            url         => $session->asset->getUrl,
            icon        => $session->asset->getIcon(1),
        };
        $var{'head.tags'} .= sprintf <<'ADMINJS', JSON->new->encode( $assetDef );
<script type="text/javascript">
if ( window.parent && window.parent.admin ) {
    window.parent.admin.navigate( %s );
}
</script>
ADMINJS
    }

    # Removing the newlines will probably annoy people. 
    # Perhaps turn it off under debug mode?
    #$var{'head.tags'} =~ s/\n//g;

	# head.tags = head_attachments . body_attachments
	# keeping head.tags for backwards compatibility
	$var{'head_attachments'} = $var{'head.tags'};
	$var{'head.tags'}       .= ($var{'body_attachments'} = '<!--morebody-->');

	my $style = eval { WebGUI::Asset->newById($self->session, $templateId); };
	my $output;
	if (! Exception::Class->caught()) {
		my $meta = {};
        	if ($self->session->setting->get("metaDataEnabled")) {
                	$meta = $style->getMetaDataFields();
        	}
        	foreach my $field (keys %$meta) {
                	$var{$meta->{$field}{fieldName}} = $meta->{$field}{value};
        	}
		$output = $style->process(\%var);
	} else {
		$output = sprintf "WebGUI was unable to instantiate your style template with the id: %s.%s", $templateId, $var{'body.content'};
	}
	WebGUI::Macro::process($self->session,\$output);
	$self->sent(1);
	my $macroHeadTags = $self->generateAdditionalHeadTags();
	my $macroBodyTags = $self->generateAdditionalBodyTags();
	$output =~ s/\<\!--morehead--\>/$macroHeadTags/;	
	$output =~ s/\<\!--morebody--\>/$macroBodyTags/;	
	return $output;
}	


#-------------------------------------------------------------------

=head2 session ( )

Returns a reference to the current session.

=cut

sub session {
	my $self = shift;
	return $self->{_session};
}

#-------------------------------------------------------------------

=head2 sent ( boolean )

Returns a boolean indicating whether the style has already been sent. This is important when trying to set things to the HTML head block.

=head3 boolean

Set the value.

=cut

sub sent {
	my $self = shift;
	my $boolean = shift;
	if (defined $boolean) {
		$self->session->stow->set("styleHeadSent",$boolean);
		return $boolean;
	}
	return $self->session->stow->get("styleHeadSent");
}

#-------------------------------------------------------------------

=head2 setLink ( url, params )

Sets a <link> tag into the <head> of this rendered page for this page
view. This is typically used for dynamically adding references to CSS
and RSS documents.  Tags are normally cached until the $style->sent
flag is set to be true.  If this method is called after that sent is
true, then the tag will be sent immediately, but will not be processed
for macros.

=head3 url

The URL to the document you are linking.  Only one link can be set per url.  If a link to this URL exists,
the old link will remain and this method will return undef.

=head3 params

A hash reference containing the other parameters to be included in the link tag, such as "rel" and "type".

=cut

sub setLink {
	my $self = shift;
	my $url = shift;
	my $params = shift;
	$params = {} unless (defined $params and ref $params eq 'HASH');
	return undef if ($self->{_link}{$url});
	my $tag = '<link href="'.$url.'"';
	foreach my $name (keys %{$params}) {
		$tag .= ' '.$name.'="'.HTML::Entities::encode($params->{$name}).'"';
	}
	$tag .= ' />'."\n";
	$self->{_link}{$url} = 1;
	$self->setRawHeadTags($tag);
}

#-------------------------------------------------------------------

=head2 setPrintableStyleId ( params )

Overrides current printable style id defined in assets definition

=head3 params

scalar containing id of style to use

=cut

sub setPrintableStyleId {
	my $self = shift;
	my $styleId = shift;

	$self->{_printableStyleId} = $styleId;
}

#-------------------------------------------------------------------

=head2 setMeta ( params )

Sets a <meta> tag into the <head> of this rendered page for this
page view.  Tags are normally cached until the $style->sent flag is
set to be true.  If this method is called after that sent is true,
then the tag will be sent immediately, but will not be processed

=head3 params

A hash reference containing the parameters of the meta tag.

=cut

sub setMeta {
	my $self = shift;
	my $params = shift;
	my $tag = '<meta';
	foreach my $name (keys %{$params}) {
		$tag .= ' '.$name.'="'.$params->{$name}.'"';
	}
	$tag .= ' />'."\n";
	$self->setRawHeadTags($tag);
}

#-------------------------------------------------------------------

sub _setRawTags {
	my $var = shift;
	return sub {
		my $self = shift;
		my $tags = shift;
		if ($self->sent) {
			$self->session->output->print($tags);
		}
		else {
			$self->{$var} .= $tags;
		}
	};
}

#-------------------------------------------------------------------

=head2 setRawBodyTags ( tags )

Does exactly the same thing as setRawHeadTags, except that the tags will be
appended to a seperate variable (to be output after the body if the style
template supports it) instead.

=cut

BEGIN { *setRawBodyTags = _setRawTags('_rawBody') }

#-------------------------------------------------------------------

=head2 setRawHeadTags ( tags )

Sets data to be output into the <head> of the current rendered page
for this page view.  Tags are normally cached until the $style->sent
flag is set to be true.  If this method is called after that sent is
true, then the tag will be sent immediately, but will not be processed
for macros.

=head3 tags

A raw string containing tags. This is just a raw string so you must actually pass in the full tag to use this call.

=cut

BEGIN { *setRawHeadTags = _setRawTags('_raw') }

#-------------------------------------------------------------------

=head2 setScript ( url, params, [inBody] )

Sets a <script> tag into the <head> of this rendered page for this
page view. This is typically used for dynamically adding references
to Javascript or ECMA script.  Tags are normally cached until the
$style->sent flag is set to be true.  If this method is called after
that sent is true, then the tag will be sent immediately, but will
not be processed for macros.

=head3 url

The URL to your script.

=head3 params

A hash reference containing the additional parameters to include in the script tag, such as "type" and "language".
Defaults to { type => 'text/javascript' } if omitted.

=head3 inBody

Optional, defaults to false.  If true, the script will be added to the
body_attachments variable instead of to head_attachments.

=cut

sub setScript {
	my $self = shift;
	my $url = shift;
	my $params = shift || { type => 'text/javascript', };
    if (! exists $params->{type}) {
        $params->{type} = 'text/javascript';
    }
	my $inBody = shift;
	return undef if ($self->{_javascript}{$url});
	my $tag = '<script src="'.$url.'"';
	foreach my $name (keys %{$params}) {
		$tag .= ' '.$name.'="'.HTML::Entities::encode($params->{$name}).'"';
	}
	$tag .= '></script>'."\n";
	$self->{_javascript}{$url} = 1;
	if ($inBody) {
		$self->setRawBodyTags($tag);
	}
	else {
		$self->setRawHeadTags($tag);
	}
}

#-------------------------------------------------------------------

=head2 useEmptyStyle ( boolean ) 

Tells the style system to use an empty style rather than outputing the normal
style. This is useful when you want your code to dynamically generate a style.

=head3 boolean

If set to 1 it will use an empty style, if set to 0 it will use the regular
style. Defaults to 0.

=cut

sub useEmptyStyle {
	my $self = shift;
	$self->{_useEmptyStyle} = shift;
}

#-------------------------------------------------------------------

=head2 userStyle ( content )

Wrapper's the content in the user style defined in the settings.

=head3 content

The content to be wrappered.

=cut

sub userStyle {
	my $self = shift;
        my $output = shift;
	$self->session->http->setCacheControl("none");
        if (defined $output) {
                return $self->process($output,$self->session->setting->get("userFunctionStyleId"));
        } else {
                return undef;
        }       
}  

1;
