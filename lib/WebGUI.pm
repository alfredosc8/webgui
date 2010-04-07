package WebGUI;


our $VERSION = '7.8.1';
our $STATUS = 'beta';


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
use MIME::Base64 ();
use WebGUI::Config;
use WebGUI::Pluggable;
use WebGUI::Session;
use WebGUI::User;
use WebGUI::Request;
use Moose;
use Try::Tiny;

has root => ( is => 'ro', isa => 'Str', default => '/data/WebGUI' );
has site => ( is => 'ro', isa => 'Str', default => 'dev.localhost.localdomain.conf' );
has session => ( is => 'rw', isa => 'WebGUI::Session' );
has config  => ( is => 'rw', isa => 'WebGUI::Config' );

use overload q(&{}) => sub { shift->psgi_app }, fallback => 1;

=head1 NAME

Package WebGUI

=head1 DESCRIPTION

PSGI handler for WebGUI.

=head1 SYNOPSIS

 use WebGUI;

=head1 SUBROUTINES

These subroutines are available from this package:

=cut

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    
    # Make constructor work as:
    #   WebGUI->new( $site )
    # In addition to the more verbose:
    #   WebGUI->new( root => $root, site => $site )
    if (@_ eq 1) {
        return $class->$orig(site => $_[0] );
    } else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;

    # Instantiate the WebGUI::Config object
    my $config = WebGUI::Config->new( $self->root, $self->site );
    $self->config($config);
}

sub psgi_app {
    my $self = shift;
    return $self->{psgi_app} ||= $self->compile_psgi_app;
}

sub compile_psgi_app {
    my $self = shift;
    
    my $app = sub {
        my $env = shift;
        
        return sub {
            my $callback = shift;
            my $request = WebGUI::Request->new($env);
            my $res = $self->dispatch($request);
            
            if ( ref $res eq 'WebGUI::Session' ) {
                my $session = $res;
                my $response = $session->response;
                
                try {
                    # Response wants to stream itself, so ask PSGI server for a 
                    # streaming writer object by returning the PSGI response, minus the body
                    
                    # Anything in the response body gets cleared (should be empty anyway)
                    $response->body([]);
                    my $psgi_response = $response->finalize;
                    
                    my $writer = $callback->( [ $psgi_response->[0], $psgi_response->[1] ] );
                    
                    # Store the writer object in the WebGUI::Response object
                    $response->writer($writer);
                    
                    # ..and let the response stream itself
                    $response->streamer->($session);
                    
                    $writer->close;
                    $session->close;
                } catch {
                    if ($response->writer) {
                        # Response has already been started, so log error and close writer
                        warn "error caught after streaming response started";
                        $response->writer->close;
                    } else {
                        $callback->( [ 500, [ 'Content-type: text/html' ], [ 'An error occurred' ] ] );
                    }
                }
            } else {
                # Not streaming, so immediately tell the callback to return 
                # the response. In the future we could use an Event framework here 
                # to make this a non-blocking delayed response.
                $callback->($res);
            }
        }
    };
    
    my $config = $self->config;

    # Extras
    use Plack::Middleware::Static;
    my $extrasURL = $config->get('extrasURL');
    my $extrasPath = $config->get('extrasPath');
    $app = Plack::Middleware::Static->wrap($app, 
        path => sub { s{^$extrasURL/}{} },
        root => "$extrasPath/",
    );
    
    # Uploads
    my $uploadsURL = $config->get('uploadsURL');
    my $uploadsPath = $config->get('uploadsPath');
    $app = Plack::Middleware::Static->wrap($app, 
        path => sub { s{^$uploadsURL/}{} }, 
        root => "$uploadsPath/", 
    );

    return $app;
}

sub dispatch {
    my ( $self, $request ) = @_;
    
    my $config = $self->config;
    
    # determine session id
    my $sessionId = $request->cookies->{$config->getCookieName};

    # Instantiate the session object
    my $session = $self->session( WebGUI::Session->open($self->root, $config, $request, $sessionId) );
    
    # Short-circuit contentHandlers - for benchmarking PSGI scaffolding vs. modperl
#    $session->close;
#    $session->output->print("WebGUI PSGI with contentHandlers short-circuited for benchmarking\n");
#    return $session->response->finalize;

    # TODO: From here, contentHandlers need to decide if they want to stream the response body:
    #  $session->response->stream( sub { ... } )            # this replaces 'chunked'
    # or return a psgi response body.
    #
    # We use the $session->response->streaming flag to detect if a contentHandler has requested
    # to use streaming response.
    #
    # Otherwise, whatever they return (arrayref or IO::Handle) is used as the psgi response
    #
    # Regular assets should use streaming response body, unless they want to send a file
    
    # Here's an example of what a contentHandler would call to do a streaming response:
    $session->response->stream(sub {
        my $session = shift;
        $session->output->print("WebGUI PSGI with contentHandlers short-circuited for benchmarking (streaming)\n");
        sleep 1;
        $session->output->print("...see?\n");
    });
    
    # Afterwards, we check $session->response->streaming, and if it is set, return the 
    # WebGUI::Session (since our caller doesn't have a reference to it) TODO - or does it via $request->session->response???
    
    # TODO: give WebGUI::Req/Res a weak session reference
    
    if ( $session->response->streaming ) {
        return $session;
    }
    
    for my $handler (@{$config->get("contentHandlers")}) {
        my $output = eval { WebGUI::Pluggable::run($handler, "handler", [ $session ] )};
        if ( my $e = WebGUI::Error->caught ) {
            $session->errorHandler->error($e->package.":".$e->line." - ".$e->error);
            $session->errorHandler->debug($e->package.":".$e->line." - ".$e->trace);
        }
        elsif ( $@ ) {
            $session->errorHandler->error( $@ );
        }
        else {
            # We decide what to do next depending on what the contentHandler returned
            
            # "chunked" or "empty" means it took care of its own output needs
            if (defined $output && ( $output eq "chunked" || $output eq "empty" )) {
                if ($session->errorHandler->canShowDebug()) {
                    $session->output->print($session->errorHandler->showDebug(),1);
                }
                last;
            }
            # non-empty output should be used as the response body
            elsif (defined $output && $output ne "") {
                # Auto-set the headers
                $session->http->sendHeader; # TODO: should be renamed setHeader
                
                # Use contentHandler's return value as the output
                $session->output->print($output);
                if ($session->errorHandler->canShowDebug()) {
                    $session->output->print($session->errorHandler->showDebug(),1);
                }
                last;
            }
            # Keep processing for success codes
            elsif ($session->http->getStatus < 200 || $session->http->getStatus > 299) {
                $session->http->sendHeader;
                last;
            }
        }
    }
    
    $session->close;
    return $session->response->finalize;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;