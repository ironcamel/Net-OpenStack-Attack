#!/usr/bin/env perl
use 5.10.0;
use strict;
use warnings;
use App::Rad;
use HTTP::Async;
use HTTP::Request;
use LWP;
use JSON qw(to_json from_json);

sub setup {
    my $ctx = shift;

    $ctx->register_commands({
        create_servers => 'create x number of servers',
        delete_servers => 'delete all servers',
        get_servers    => 'run x number of server list requests',
        get_images     => 'run x number of image list requests',
        bad            => 'run x number of bad/invalid requests',
    });

    # Construct the base url
    my $base_url = $ENV{NOVA_URL};
    die "NOVA_URL env var is missing. Did you forget to source novarc?\n"
        unless $base_url;
    $base_url =~ s(/$)();       # Remove trailing slash
    $base_url =~ s/v1\.0/v1.1/; # Switch to version 1.1
    $ctx->stash->{base_url} = $base_url;

    # Save the auth token
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get(
        $base_url,
        'x-auth-key'  => $ENV{NOVA_API_KEY},
        'x-auth-user' => $ENV{NOVA_USERNAME},
    );  
    $ctx->stash->{auth_headers} = [
        'x-auth-token' => $res->header('x-auth-token'),
        'content-type' => 'application/json'
    ];
}

sub pre_process {
    my $ctx = shift;
    $ctx->stash->{num_runs} = $ARGV[0] || 1;
}

App::Rad->run();

#---------- Commands ----------------------------------------------------------

sub create_servers {
    my $ctx = shift;
    my $num_runs = $ctx->stash->{num_runs};
    my $body = to_json {
        server => {
            name      => 'test-server',
            imageRef  => 3,
            flavorRef => 1,
        }
    };
    my @reqs = map makereq($ctx, POST => '/servers', $body), 1 .. $num_runs;
    say "Creating $num_runs servers...";
    return sendreqs(@reqs);
}

sub delete_servers {
    my $ctx = shift;

    die "The delete_servers command does not accept any arguments\n" if @ARGV;

    my $ua = LWP::UserAgent->new();
    my $base_url = $ctx->stash->{base_url};
    my $res = $ua->get("$base_url/servers", @{ $ctx->stash->{auth_headers} });

    die "Error getting server list: " . $res->content unless $res->is_success;

    my $data = from_json($res->content);
    my @servers = @{ $data->{servers} };
    my @reqs = map makereq($ctx, DELETE => "/servers/$_->{id}"), @servers;
    say "Deleting " . @servers . " servers...";
    return sendreqs(@reqs);
}

sub bad {
    my $ctx = shift;
    my $num_runs = $ctx->stash->{num_runs};
    my @reqs = map makereq($ctx, GET => '/bad'), 1 .. $num_runs;
    say "Sending $num_runs /bad requests...";
    return sendreqs(@reqs);
}

sub get_images {
    my $ctx = shift;
    my $num_runs = $ctx->stash->{num_runs};
    my @reqs = map makereq($ctx, GET => '/images'), 1 .. $num_runs;
    say "Sending $num_runs /images requests...";
    return sendreqs(@reqs);
}

sub get_servers {
    my $ctx = shift;
    my $num_runs = $ctx->stash->{num_runs};
    my @reqs = map makereq($ctx, GET => '/servers'), 1 .. $num_runs;
    say "Sending $num_runs /servers requests...";
    return sendreqs(@reqs);
}

#---------- Helpers -----------------------------------------------------------

sub makereq {
    my ($ctx, $method, $resource, $body) = @_;
    my $url = $ctx->stash->{base_url} . $resource;
    my $headers = $ctx->stash->{auth_headers};
    return HTTP::Request->new($method => $url, $headers, $body);
}

sub sendreqs {
    my @reqs = @_;
    my $async = HTTP::Async->new;
    $async->add(@reqs);
    my ($successes, $failures, @errmsgs) = (0, 0);
    while (my $res = $async->wait_for_next_response) {
        if ($res->is_success) {
            $successes++;
        } else {
            $failures++;
            push @errmsgs, $res->content;
        }
    }
    return "Successes: $successes Failures: $failures";
}
