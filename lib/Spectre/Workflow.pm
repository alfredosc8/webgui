package Spectre::Workflow;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2006 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use HTTP::Request::Common;
use HTTP::Cookies;
use POE qw(Component::Client::HTTP);
use WebGUI::Session;

#-------------------------------------------------------------------

=head2 _start ( )

Initializes the workflow manager.

=cut

sub _start {
        my ( $kernel, $self, $publicEvents) = @_[ KERNEL, OBJECT, ARG0 ];
	$self->debug("Starting workflow manager.");
        my $serviceName = "workflow";
        $kernel->alias_set($serviceName);
        $kernel->call( IKC => publish => $serviceName, $publicEvents );
	$self->debug("Reading workflow configs.");
	my $configs = WebGUI::Config->readAllConfigs($self->config->getWebguiRoot);
	foreach my $config (keys %{$configs}) {
		next if $config =~ m/^demo/;
		$kernel->yield("loadWorkflows", $configs->{$config});
	}
        $kernel->yield("checkInstances");
}

#-------------------------------------------------------------------

=head2 _stop ( )

Gracefully shuts down the workflow manager.

=cut

sub _stop {
	my ($kernel, $self) = @_[KERNEL, OBJECT];	
	$self->debug("Stopping workflow manager.");
	undef $self;
}

#-------------------------------------------------------------------

=head2 addInstance ( params )

Adds a workflow instance to the workflow processing queue.

=head3 params

A hash reference containing important information about the workflow instance to add to the queue.

=head4 sitename

The host and domain of the site this instance belongs to.

=head4 instanceId

The unqiue id for this workflow instance.

=head4 priority

The priority (1,2, or 3) that this instance should be run at.

=cut

sub addInstance {
	my ($self, $params) = @_[OBJECT, ARG0];
	$self->debug("Adding workflow instance ".$params->{instanceId}." from ".$params->{sitename}." to queue at priority ".$params->{priority}.".");
	$self->{_instances}{$params->{instanceId}} = {
		sitename=>$params->{sitename},
		instanceId=>$params->{instanceId},
		gateway => $params->{gateway},
		status=>"waiting",
		priority=>$params->{priority}
		};
	push(@{$self->{"_priority".$params->{priority}}}, $params->{instanceId});
}

#-------------------------------------------------------------------

=head2 checkInstances ( )

Checks to see if there are any open instance slots available, and if there are assigns a new instance to be run to fill it.

=cut
use POE::API::Peek;

sub checkInstances {
	my ($kernel, $self) = @_[KERNEL, OBJECT];
	$self->debug("Checking to see if we can run anymore instances right now.");
	if ($self->countRunningInstances < $self->config->get("maxWorkers")) {
		my $api = POE::API::Peek->new;
		$self->debug("POE SESSIONS: ".$api->session_count);
		$self->debug("Total workflows waiting to run: ".scalar(keys %{$self->{_instances}}));
		$self->debug("Priority 1 count: ".scalar(@{$self->{_priority1}}));
                $self->debug("Priority 2 count: ".scalar(@{$self->{_priority2}}));
                $self->debug("Priority 3 count: ".scalar(@{$self->{_priority3}}));
		my $instance = $self->getNextInstance;
		if (defined $instance) {
			# mark it running so that it doesn't run twice at once
			$instance->{status} = "running";
			push(@{$self->{_runningInstances}}, $instance->{instanceId});
			# put it at the end of the queue so that others get a chance
			my $priority = $self->{_instances}{$instance->{instanceId}}{priority};
			for (my $i=0; $i < scalar(@{$self->{"_priority".$priority}}); $i++) {
				if ($self->{"_priority".$priority}[$i] eq $instance->{instanceId}) {
					splice(@{$self->{"_priority".$priority}}, $i, 1);
				}
			}
			push(@{$self->{"_priority".$priority}}, $instance->{instanceId});
			# run it already
			$kernel->yield("runWorker",$instance);
		}
	}	
	$kernel->delay_set("checkInstances",$self->config->get("timeBetweenRunningWorkflows"));
}

#-------------------------------------------------------------------

=head2 config ( )

Returns a reference to the config object.

=cut 

sub config {
	my $self = shift;
	return $self->{_config};
}

#-------------------------------------------------------------------

=head2 countRunningInstances ( )

Returns an integer representing the number of running instances.

=cut

sub countRunningInstances {
	my $self = shift;
	my $runningInstances = $self->{_runningInstances};
	my $instanceCount = scalar(@{$runningInstances});
	$self->debug("There are $instanceCount running instances.");
	return $instanceCount;
}

#-------------------------------------------------------------------

=head2 debug ( output )

Prints out debug information if debug is enabled.

=head3 output

The debug message to be printed if debug is enabled.

=cut 

sub debug {
	my $self = shift;
	my $output = shift;
	if ($self->{_debug}) {
		print "WORKFLOW: ".$output."\n";
	}
	$self->getLogger->debug("WORKFLOW: ".$output);
}

#-------------------------------------------------------------------

=head2 deleteInstance ( instanceId ) 

Removes a workflow instance from the processing queue.

=cut

sub deleteInstance {
	my ($self, $instanceId,$kernel, $session ) = @_[OBJECT, ARG0, KERNEL, SESSION];
	$self->debug("Deleting workflow instance $instanceId from queue.");
	$self->removeInstanceFromRunningQueue($instanceId);
	if ($self->{_instances}{$instanceId}) {
		my $priority = $self->{_instances}{$instanceId}{priority};
		unless ($priority) {
			$priority = 2;
			$self->error("Workflow instance $instanceId has no priority set. This is likely the cause of a bug somewhere in the system. Temporarily setting the priority to 2 to avoid a fatal error.");
		}
		delete $self->{_errorCount}{$instanceId};
		delete $self->{_instances}{$instanceId};
		for (my $i=0; $i < scalar(@{$self->{"_priority".$priority}}); $i++) {
			if ($self->{"_priority".$priority}[$i] eq $instanceId) {
				splice(@{$self->{"_priority".$priority}}, $i, 1);
			}
		}
	}
}

#-------------------------------------------------------------------

=head2 error ( output )

Prints out error information if debug is enabled.

=head3 output

The error message to be printed if debug is enabled.

=cut 

sub error {
	my $self = shift;
	my $output = shift;
	if ($self->{_debug}) {
		print "WORKFLOW: [Error] ".$output."\n";
	}
	$self->getLogger->error("WORKFLOW: ".$output);
}

#-------------------------------------------------------------------

=head3 getLogger ( )

Returns a reference to the logger.

=cut

sub getLogger {
	my $self = shift;
	return $self->{_logger};
}

#-------------------------------------------------------------------

=head2 getNextInstance ( )

=cut

sub getNextInstance {
	my $self = shift;
	$self->debug("Looking for a workflow instance to run.");
	foreach my $priority (1..3) {
		foreach my $instanceId (@{$self->{"_priority".$priority}}) {
			if ($self->{_instances}{$instanceId}{status} eq "waiting") {
				$self->debug("Looks like ".$instanceId." would be a good workflow instance to run.");
				return $self->{_instances}{$instanceId};
			}
		}
	}
	$self->debug("Didn't see any workflow instances to run.");
	return undef;
}

#-------------------------------------------------------------------

=head2 loadWorkflows ( )

=cut 

sub loadWorkflows {
	my ($kernel, $self, $config) = @_[KERNEL, OBJECT, ARG0];
	$self->debug("Loading workflows for ".$config->getFilename.".");
	my $session = WebGUI::Session->open($config->getWebguiRoot, $config->getFilename);
	my $result = $session->db->read("select instanceId,priority from WorkflowInstance");
	while (my ($id, $priority) = $result->array) {
		$kernel->yield("addInstance", {gateway=>$config->get("gateway"), sitename=>$config->get("sitename")->[0], instanceId=>$id, priority=>$priority});
	}
	$result->finish;
	$session->close;
}

#-------------------------------------------------------------------

=head2 new ( config, logger, [ , debug ] )

Constructor. Loads all active workflows from each WebGUI site and begins executing them.

=head3 config

The config object for spectre.

=head3 logger

A reference to the logger object.

=head3 debug

A boolean indicating Spectre should spew forth debug as it runs.

=cut

sub new {
	my $class = shift;
	my $config = shift;
	my $logger = shift;
	my $debug = shift;
	my $self = {_runningInstances=>[], _priority1=>[], _priority2=>[], _priority3=>[], _debug=>$debug, _config=>$config, _logger=>$logger};
	bless $self, $class;
	my @publicEvents = qw(addInstance deleteInstance);
	POE::Session->create(
		object_states => [ $self => [qw(_start _stop returnInstanceToRunnableState addInstance checkInstances deleteInstance suspendInstance loadWorkflows runWorker workerResponse), @publicEvents] ],
		args=>[\@publicEvents]
        	);
	my $cookies = HTTP::Cookies->new(file => '/tmp/cookies');
	POE::Component::Client::HTTP->spawn(
		Agent => 'Spectre',
		Alias => 'workflow-ua',
		CookieJar => $cookies
  		);
}

#-------------------------------------------------------------------

=head2 removeInstanceFromRunningQueue ( )

Removes a workflow instance from the queue that tracks what's running.

=cut

sub removeInstanceFromRunningQueue {
	my $self = shift;
	my $instanceId = shift;
	return undef unless defined $instanceId;
	for (my $i=0; $i < scalar(@{$self->{_runningInstances}}); $i++) {
		if ($self->{_runningInstances}[$i] eq $instanceId) {
			splice(@{$self->{_runningInstances}}, $i, 1);
		}
	}
}

#-------------------------------------------------------------------

=head2 returnInstanceToRunnableState ( )

Returns a workflow instance back to runnable queue.

=cut

sub returnInstanceToRunnableState {
	my ($self, $instanceId) = @_[OBJECT, ARG0];
	$self->debug("Returning ".$instanceId." to runnable state.");
	if ($self->{_instances}{$instanceId}) {
		$self->{_instances}{$instanceId}{status} = "waiting";
	}
}

#-------------------------------------------------------------------

=head2 runWorker ( )

Calls a worker to execute a workflow activity.

=cut

sub runWorker {
	my ($kernel, $self, $instance, $session) = @_[KERNEL, OBJECT, ARG0, SESSION];
	$self->debug("Preparing to run workflow instance ".$instance->{instanceId}.".");
	my $url = "http://".$instance->{sitename}.':'.$self->config->get("webguiPort").$instance->{gateway};
	my $request = POST $url, [op=>"runWorkflow", instanceId=>$instance->{instanceId}];
	my $cookie = $self->{_cookies}{$instance->{sitename}};
	$request->header("Cookie","wgSession=".$cookie) if (defined $cookie);
	$request->header("X-instanceId",$instance->{instanceId});
	$request->header("User-Agent","Spectre");
	$self->debug("Posting workflow instance ".$instance->{instanceId}." to $url.");
	$kernel->post('workflow-ua','request', 'workerResponse', $request);
	$self->debug("Workflow instance ".$instance->{instanceId}." posted.");
}

#-------------------------------------------------------------------

=head2 suspendInstance ( ) 

Suspends a workflow instance for a number of seconds defined in the config file, and then returns it to the runnable queue.

=cut

sub suspendInstance {
	my ($self, $instanceId, $kernel) = @_[OBJECT, ARG0, KERNEL];
	if ($self->{_errorCount}{$instanceId} >= 5) {
		$self->error("Workflow instance $instanceId has failed to execute ".$self->{_errorCount}{$instanceId}." times in a row and will no longer attempt to execute.");
		$kernel->yield("deleteInstance",$instanceId);
	} else {
		$self->debug("Suspending workflow instance ".$instanceId." for ".$self->config->get("suspensionDelay")." seconds.");
		$kernel->delay_set("returnInstanceToRunnableState",$self->config->get("suspensionDelay"), $instanceId);
	}
}

#-------------------------------------------------------------------

=head2 workerResponse ( )

This method is called when the response from the runWorker() method is received.

=cut

sub workerResponse {
	my ($self, $kernel, $requestPacket, $responsePacket) = @_[OBJECT, KERNEL, ARG0, ARG1];
	$self->debug("Retrieving response from workflow instance.");
 	my $request  = $requestPacket->[0];
    	my $response = $responsePacket->[0];
	my $instanceId = $request->header("X-instanceId");	# got to figure out how to get this from the request, cuz the response may die
	$self->debug("Response retrieved is for $instanceId.");
	$self->removeInstanceFromRunningQueue($instanceId);
	if ($response->is_success) {
		$self->debug("Response for $instanceId retrieved successfully.");
		if ($response->header("Set-Cookie") ne "") {
			$self->debug("Storing cookie for $instanceId for later use.");
			my $cookie = $response->header("Set-Cookie");
			$cookie =~ s/wgSession=([a-zA-Z0-9\_\-]{22}).*/$1/;
			$self->{_cookies}{$self->{_instances}{$instanceId}{sitename}} = $cookie;
		}
		my $state = $response->content; 
		if ($state eq "waiting") {
			delete $self->{_errorCount}{$instanceId};
			$self->debug("Was told to wait on $instanceId because we're still waiting on some external event.");
			$kernel->yield("suspendInstance",$instanceId);
		} elsif ($state eq "complete") {
			delete $self->{_errorCount}{$instanceId};
			$self->debug("Workflow instance $instanceId ran one of it's activities successfully.");
			$kernel->yield("returnInstanceToRunnableState",$instanceId);
		} elsif ($state eq "disabled") {
			delete $self->{_errorCount}{$instanceId};
			$self->debug("Workflow instance $instanceId is disabled.");
			$kernel->yield("suspendInstance",$instanceId);			
		} elsif ($state eq "done") {
			$self->debug("Workflow instance $instanceId is now complete.");
			$kernel->yield("deleteInstance",$instanceId);			
		} elsif ($state eq "error") {
			$self->{_errorCount}{$instanceId}++;
			$self->debug("Got an error response for $instanceId.");
			$kernel->yield("suspendInstance",$instanceId);
		} else {
			$self->{_errorCount}{$instanceId}++;
			$self->error("Something bad happened on the return of $instanceId. ".$response->error_as_HTML);
			$kernel->yield("suspendInstance",$instanceId);
		}
	} elsif ($response->is_redirect) {
		$self->error("Response for $instanceId was redirected. This should never happen if configured properly!!!");
	} elsif ($response->is_error) {	
		$self->{_errorCount}{$instanceId}++;
		$self->error("Response for $instanceId had a communications error. ".$response->error_as_HTML);
		$kernel->yield("suspendInstance",$instanceId)
	}
}


1;
