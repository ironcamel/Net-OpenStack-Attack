#!/usr/bin/env perl
use 5.10.0;
use strict;
use warnings;
use AnyEvent::HTTP;
use Data::Dumper;
use LWP;
use HTTP::Request;
use JSON qw(from_json to_json);

my ($action, $num_runs) = @ARGV;
die "action argument required, e.g., create_servers\n" unless $action;
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
my $auth_head = {headers => {
    "x-auth-token" => $token,
    "content-type" => "application/json"
}};


########################
# BODY CREATE JSON
########################
my $create_body = to_json({
        server => {
            name     => 'test-server',
            imageRef  => '3',
            flavorRef => '1',
        }
    });


my $c1 = AnyEvent->condvar;

given ($action){
    ########################
    # CREATE SERVERS
    ########################
    when ("create_servers") {
        my ($successes, $failures, @errmsgs) = (0, 0);
        say "Creating $num_runs servers...";
        for my $i (1 .. $num_runs) {
            $c1->begin;
            http_post "$base_url/servers", $create_body, %$auth_head, sub {
                my ($body, $headers) = @_;
                if ($headers->{Status} =~ /^2/){
                    $successes++;
                }else{
                    $failures++;
                    push @errmsgs, Dumper($headers);
                };
                $c1->end;
            };
        }
        $c1->recv;
        say "Successes: $successes Failures: $failures.";
        say Dumper(@errmsgs) if @errmsgs;
    }

    ########################
    # DELETE SERVERS
    ########################
    when ("delete_servers") {
        $c1->begin;
        my ($successes, $failures, @errmsgs) = (0, 0);
        http_get "$base_url/servers", %$auth_head, sub {
            my ($body, $headers) = @_;
            die "Error getting server list" 
                unless $headers->{Status} =~ /^2/;
            $body = from_json $body;
            my @servers = @{ $body->{servers} };
            my $num_servers = @servers;
            say "Deleting $num_servers servers...";
            foreach my $server (@servers){
                $c1->begin;
                my $id = $server->{id};
                http_request "DELETE", "$base_url/servers/$id", %$auth_head,
                sub {
                    my ($body, $headers) = @_;
                    if($headers->{Status} =~ /^2/){
                        $successes++;
                    } else {
                        $failures++;
                        push @errmsgs, Dumper($headers);
                    }
                    $c1->end;
                }
            }
            $c1->end;
        };

        $c1->recv;
        say "Successes: $successes Failures: $failures";
        say Dumper(@errmsgs) if @errmsgs;
    }
}

