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
        servers => 'run x number of server list requests',
        bad => 'run x number of bad/invalid requests',
        images => 'run x number of image list requests',
    });
}

sub pre_process
{
    my $c = shift;
    my ($num_runs) = @ARGV;
    $num_runs ||= 1;
    $c->stash->{num_runs} = $num_runs;

    $c->stash->{async} = HTTP::Async->new;
    $c->stash->{ua} = LWP::UserAgent->new();

    my $base_url = $ENV{NOVA_URL};
    $base_url =~ s(/$)();       # Remove trailing slash
    $base_url =~ s/v1\.0/v1.1/; # Switch to version 1.1
    $c->stash->{base_url} = $base_url;

    # Get the Auth Token
    my $res = $c->stash->{ua}->get($base_url,
        'X-Auth-Key'  => $ENV{NOVA_API_KEY},
        'X-Auth-User' => $ENV{NOVA_USERNAME},
    );  

    # Store auth_headers
    $c->stash->{auth_headers} = [
        "x-auth-token" => $res->header('x-auth-token'),
        "content-type" => "application/json"
    ];

    $c->stash->{create_body_json} = to_json({
        server => {
            name     => 'test-server',
            imageRef  => '3',
            flavorRef => '1',
        }
    });
}

sub post_process
{
    my $c = shift;
    my $data = $c->output;
    say "Successes: " . $data->[0] . " Failures: " . $data->[1];
}

App::Rad->run();

#---------- Helpers -----------------------------------------------------------

sub make_requests 
{
    #my ($url, $headers, $body) = 

}

#---------- Commands ----------------------------------------------------------


sub create_servers 
{
    my $c = shift;
    my $async = $c->stash->{async};
    my $num_runs = $c->stash->{num_runs};
    my $base_url = $c->stash->{base_url};
    my ($successes, $failures, @errmsgs) = (0, 0);

    say "Creating $num_runs servers...";
    for my $i (1 .. $num_runs) {
        my $req = HTTP::Request->new(
            POST => "$base_url/servers", 
            $c->stash->{auth_headers}, 
            $c->stash->{create_body_json});
        $async->add($req);
    }
    while (my $res = $async->wait_for_next_response) {
        if ($res->status_line =~ /^2/){
            $successes++;
        } else {
            $failures++;
            push @errmsgs, $res->content;
        }
    }
    return [$successes, $failures];
}

sub delete_servers 
{
    my $c = shift;
    my $async = $c->stash->{async};
    my $num_runs = $c->stash->{num_runs};
    my $ua = $c->stash->{ua};
    my $base_url = $c->stash->{base_url};
    my ($successes, $failures, @errmsgs) = (0, 0);

    my $res = $ua->get("$base_url/servers", $c->stash->{auth_headers});
    die "Error getting server list" unless $res->status_line =~ /^2/;
    my $data = from_json($res->content);
    my @servers = @{ $data->{servers} };
    my $num_servers = @servers;
    say "Deleting $num_servers servers...";
    foreach my $server (@servers){
        my $id = $server->{id};
        my $req = HTTP::Request->new(
            DELETE => "$base_url/servers/$id", $c->stash->{auth_headers});
        $async->add($req);
        while (my $res = $async->wait_for_next_response) {
            if ($res->status_line =~ /^2/) {
                $successes++;
            } else {
                $failures++;
                push @errmsgs, $res->content;
            }
        }
    }

    return [$successes, $failures];
}

sub bad 
{
    my $c = shift;
    my $async = $c->stash->{async};
    my $num_runs = $c->stash->{num_runs};
    my $base_url = $c->stash->{base_url};
    my ($successes, $failures, @errmsgs) = (0, 0);

    say "Sending $num_runs invalid requests...";
    for my $i (1 .. $num_runs) {
        my $req = HTTP::Request->new(
            GET => "$base_url/invalid-resource", $c->stash->{auth_headers});
        $async->add($req);
    }
    while (my $res = $async->wait_for_next_response) {
        if ($res->status_line =~ /^2/){
            $successes++;
        } else {
            $failures++;
            push @errmsgs, $res->content;
        }
    }
    return [$successes, $failures];
}

sub images
{
    my $c = shift;
    my $async = $c->stash->{async};
    my $num_runs = $c->stash->{num_runs};
    my $base_url = $c->stash->{base_url};
    my ($successes, $failures, @errmsgs) = (0, 0);

    say "Sending $num_runs /images requests...";
    for my $i (1 .. $num_runs) {
        my $req = HTTP::Request->new(
            GET => "$base_url/images", $c->stash->{auth_headers});
        $async->add($req);
    }
    while (my $res = $async->wait_for_next_response) {
        if ($res->status_line =~ /^2/){
            $successes++;
        } else {
            $failures++;
            push @errmsgs, $res->content;
        }
    }
    return [$successes, $failures];
}

sub servers 
{
    my $c = shift;
    my $async = $c->stash->{async};
    my $num_runs = $c->stash->{num_runs};
    my $base_url = $c->stash->{base_url};
    my ($successes, $failures, @errmsgs) = (0, 0);

    say "Sending $num_runs /servers requests...";
    for my $i (1 .. $num_runs) {
        my $req = HTTP::Request->new(
            GET => "$base_url/servers", $c->stash->{auth_headers});
        $async->add($req);
    }
    while (my $res = $async->wait_for_next_response) {
        if ($res->status_line =~ /^2/){
            $successes++;
        } else {
            $failures++;
            push @errmsgs, $res->content;
        }
    }
    return [$successes, $failures];
}
