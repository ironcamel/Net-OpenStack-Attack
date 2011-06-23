#!/usr/bin/env perl
use 5.10.0;
use strict;
use warnings;
use HTTP::Async;
use HTTP::Request;
use App::Rad;
use LWP;
use JSON qw(to_json from_json);

sub setup {
    my $c = shift;

    $c->register_commands({
        create_servers => 'create x number of servers',
        delete_servers => 'delete all servers',
        servers        => 'run x number of server list requests',
        images         => 'run x number of image list requests',
        bad            => 'run x number of bad/invalid requests',
    });

    # Construct the base url
    my $base_url = $ENV{NOVA_URL};
    die "NOVA_URL env var is missing. Did you forget to source novarc?\n"
        unless $base_url;
    $base_url =~ s(/$)();       # Remove trailing slash
    $base_url =~ s/v1\.0/v1.1/; # Switch to version 1.1
    $c->stash->{base_url} = $base_url;

    # Save the auth token
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get(
        $base_url,
        'x-auth-key'  => $ENV{NOVA_API_KEY},
        'x-auth-user' => $ENV{NOVA_USERNAME},
    );  
    $c->stash->{auth_headers} = [
        "x-auth-token" => $res->header('x-auth-token'),
        "content-type" => "application/json"
    ];
}

sub pre_process {
    my $c = shift;
    $c->stash->{num_runs} = $ARGV[0] || 1;
}

sub post_process {
    my $c = shift;
    my $output = $c->output;
    if (ref $output eq 'ARRAY') {
        say "Successes: $output->[0] Failures: $output->[1]";
    } else {
        say $output;
    }
}

App::Rad->run();

#---------- Commands ----------------------------------------------------------

sub create_servers {
    my $c = shift;
    say "Creating " . $c->stash->{num_runs} . " servers...";
    return make_requests($c, POST => '/servers', to_json {
        server => {
            name      => 'test-server',
            imageRef  => 3,
            flavorRef => 1,
        }
    });
}

sub delete_servers {
    my $c = shift;

    die "The delete_servers command does not accept any arguments\n" if @ARGV;

    my $ua = LWP::UserAgent->new();
    my $base_url = $c->stash->{base_url};
    my $res = $ua->get("$base_url/servers", @{ $c->stash->{auth_headers} });

    die "Error getting server list " . $res->content
        unless $res->status_line =~ /^2/;

    my $data = from_json($res->content);
    my @servers = @{ $data->{servers} };

    say "Deleting " . @servers . " servers...";
    my ($successes, $failures, @errmsgs) = (0, 0);
    foreach my $server (@servers){
        my $id = $server->{id};
        my $reval = make_requests($c, DELETE => "/servers/$id");
        $successes += $reval->[0];
        $failures += $reval->[1];
    }
    return [$successes, $failures];
}

sub bad {
    my $c = shift;
    say "Sending " . $c->stash->{num_runs} . " invalid requests...";
    return make_requests($c, GET => '/invalid-resource');
}

sub images {
    my $c = shift;
    say "Sending " . $c->stash->{num_runs} . " /images requests...";
    return make_requests($c, GET => '/images');
}

sub servers {
    my $c = shift;
    say "Sending " . $c->stash->{num_runs} . " /servers requests...";
    return make_requests($c, GET => '/servers');
}

#---------- Helpers -----------------------------------------------------------

sub make_requests {
    my ($c, $method, $resource, $body) = @_;
    my $url = $c->stash->{base_url} . $resource;
    my $headers = $c->stash->{auth_headers};
    my ($successes, $failures, @errmsgs) = (0, 0);
    my $async = HTTP::Async->new;

    for my $i (1 .. $c->stash->{num_runs}) {
        my $req = HTTP::Request->new($method => $url, $headers, $body);
        $async->add($req);
    }
    while (my $res = $async->wait_for_next_response) {
        if ($res->status_line =~ /^2/) {
            $successes++;
        } else {
            $failures++;
            push @errmsgs, $res->content;
        }
    }
    return [$successes, $failures];
}
