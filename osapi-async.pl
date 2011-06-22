#!/usr/bin/env perl
use 5.10.0;
use strict;
use warnings;
use Data::Dumper;
use HTTP::Async;
use HTTP::Request;
use App::Rad;
use LWP;
use JSON qw(to_json from_json);

my ($action, $num_runs) = @ARGV;
$num_runs ||= 1;

my $base_url = $ENV{NOVA_URL};
$base_url =~ s(/$)();       # Remove trailing slash
$base_url =~ s/v1\.0/v1.1/; # Switch to version 1.1

########################
# GET AUTH TOKEN
########################
my $ua = LWP::UserAgent->new();
my $res = $ua->get($base_url,
    'X-Auth-Key'  => $ENV{NOVA_API_KEY},
    'X-Auth-User' => $ENV{NOVA_USERNAME},
);  
my $token = $res->headers->header('x-auth-token');
$ua->default_header('X-Auth-Token' => $token);
my $auth_headers = [
    "x-auth-token" => $token,
    "content-type" => "application/json"
];


App::Rad->run();

########################
# CREATE BODY JSON
########################
my $create_body = to_json({
    server => {
        name     => 'test-server',
        imageRef  => '3',
        flavorRef => '1',
    }
});

sub create_servers 
:Help(create x number of servers)
{
    my ($successes, $failures, @errmsgs) = (0, 0);
    my $async = HTTP::Async->new;

    say "Creating $num_runs servers...";
    for my $i (1 .. $num_runs) {
        my $req = HTTP::Request->new(
            POST => "$base_url/servers", $auth_headers, $create_body);
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
    say "Successes: $successes Failures: $failures.";
    #say Dumper(\@errmsgs) if @errmsgs;
}

sub delete_servers 
:Help(delete all servers)
{
    my ($successes, $failures, @errmsgs) = (0, 0);
    my $async = HTTP::Async->new;
    my $res = $ua->get("$base_url/servers", $auth_headers);
    die "Error getting server list" unless $res->status_line =~ /^2/;
    my $data = from_json($res->content);
    my @servers = @{ $data->{servers} };
    my $num_servers = @servers;
    say "Deleting $num_servers servers...";
    foreach my $server (@servers){
        my $id = $server->{id};
        my $req = HTTP::Request->new(
            DELETE => "$base_url/servers/$id", $auth_headers);
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

    say "Successes: $successes Failures: $failures";
    #say Dumper(\@errmsgs) if @errmsgs;
}

sub invalid 
:Help(run invalid request x number of times)
{
    my ($successes, $failures, @errmsgs) = (0, 0);
    my $async = HTTP::Async->new;
    say "Sending $num_runs invalid requests...";
    for my $i (1 .. $num_runs) {
        my $req = HTTP::Request->new(
            GET => "$base_url/invalid-resource", $auth_headers, $create_body);
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
    say "Successes: $successes Failures: $failures.";
    #say Dumper(\@errmsgs) if @errmsgs;
}

sub images
:Help(run images request x number of times)
{
    my ($successes, $failures, @errmsgs) = (0, 0);
    my $async = HTTP::Async->new;
    say "Sending $num_runs /images requests...";
    for my $i (1 .. $num_runs) {
        my $req = HTTP::Request->new(
            GET => "$base_url/images", $auth_headers, $create_body);
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
    say "Successes: $successes Failures: $failures.";
    #say Dumper(\@errmsgs) if @errmsgs;
}

sub servers 
:Help(run server list request x number of times)
{
    my ($successes, $failures, @errmsgs) = (0, 0);
    my $async = HTTP::Async->new;
    say "Sending $num_runs /servers requests...";
    for my $i (1 .. $num_runs) {
        my $req = HTTP::Request->new(
            GET => "$base_url/servers", $auth_headers, $create_body);
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
    say "Successes: $successes Failures: $failures.";
    #say Dumper(\@errmsgs) if @errmsgs;
}
