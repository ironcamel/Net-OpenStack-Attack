#!/usr/bin/env perl
use perl5i::2;
use App::Rad;
use HTTP::Async;
use HTTP::Request;
use JSON qw(to_json from_json);
use LWP;
use Time::SoFar qw(runtime);

my %auth_methods = (
    'v1.1' => func($ua, $base_url) {
        my $res = $ua->get($base_url,
            'X-Auth-Key'  => $ENV{NOVA_API_KEY},
            'X-Auth-User' => $ENV{NOVA_USERNAME},
            'X-Auth-Project-Id' => $ENV{NOVA_PROJECT_ID},
        );
        #say $res->headers->as_string;
        die $res->status_line . "\n" . $res->content unless $res->is_success;

        return (
            $res->header('x-server-management-url'),
            $res->header('x-auth-token')
        );
    },

    'v2.0' => func($ua, $base_url) {
        my $auth_data = {
            auth =>  {
                passwordCredentials => {
                    username => $ENV{NOVA_USERNAME},
                    password => $ENV{NOVA_API_KEY},
                }
            }
        };

        my $res = $ua->post("$base_url/tokens",
            content_type => 'application/json', Content => to_json($auth_data));
        
        die $res->status_line . "\n" . $res->content unless $res->is_success;
        my $data = from_json($res->content);
        my $token = $data->{access}{token}{id};

        my ($catalog) =
            grep { $_->{type} eq 'compute' } @{$data->{access}{serviceCatalog}};
        die "No compute service catalog found" unless $catalog;

        $base_url = $catalog->{endpoints}[0]{publicURL};
        if ($ENV{NOVA_REGION_NAME}) {
            for my $endpoint (@{ $catalog->{endpoints} }) {
                if ($endpoint->{region} eq $ENV{NOVA_REGION_NAME}) {
                    $base_url = $endpoint->{publicURL};
                    last;
                }
            }
        }
        return ($base_url, $token);
    }
);

func setup($ctx) {
    $ctx->register_commands({
        create_servers => 'create x number of servers',
        delete_servers => 'delete all servers',
        get_servers    => 'run x number of server list requests',
        get_images     => 'run x number of image list requests',
        bad            => 'run x number of bad/invalid requests',
    });

    # Determine the version
    my $base_url = $ENV{NOVA_URL};
    die "NOVA_URL env var is missing. Did you forget to source a novarc?\n"
        unless $base_url;
    $base_url =~ s{/$}{}; # Remove trailing slash if it exists
    my ($version) = $base_url =~ /(v\d\.\d)$/;
    die "Could not determine version from url [$base_url]"
        unless $version;

    # Do auth and stash the auth token and base url
    my $ua = LWP::UserAgent->new();
    my $auth_method = $auth_methods{$version}
        or die "version [$version] is not supported";
    my ($real_base_url, $token) = $auth_method->($ua, $base_url);
    $ctx->stash->{base_url} = $real_base_url;
    $ctx->stash->{auth_headers} = [
        'x-auth-token' => $token,
        'content-type' => 'application/json',
    ];
}

func pre_process($ctx) {
    $ctx->getopt('verbose|v', 'image|i=s');
    $ctx->stash->{num_runs} = $ctx->argv->[0] || 1;
}

#---------- Commands ----------------------------------------------------------

func create_servers($ctx) {
    my $num_runs = $ctx->stash->{num_runs};
    my $image = $ctx->options->{image} or die "--image option required";
    my $body = to_json {
        server => {
            name      => 'test-server',
            imageRef  => $image,
            flavorRef => 1,
        }
    };
    my @reqs = map makereq($ctx, POST => '/servers', $body), 1 .. $num_runs;
    say "Creating $num_runs servers...";
    return sendreqs($ctx, @reqs);
}

func delete_servers($ctx) {
    my $ua = LWP::UserAgent->new();
    my $base_url = $ctx->stash->{base_url};
    my $res = $ua->get("$base_url/servers", @{ $ctx->stash->{auth_headers} });

    die "Error getting server list: " . $res->content unless $res->is_success;

    my $data = from_json($res->content);
    my @servers = @{ $data->{servers} };
    my @reqs = map makereq($ctx, DELETE => "/servers/$_->{id}"), @servers;
    say "Deleting " . @servers . " servers...";
    return sendreqs($ctx, @reqs);
}

func bad($ctx) {
    my $num_runs = $ctx->stash->{num_runs};
    my @reqs = map makereq($ctx, GET => '/bad'), 1 .. $num_runs;
    say "Sending $num_runs /bad requests...";
    return sendreqs($ctx, @reqs);
}

func get_images($ctx) {
    my $num_runs = $ctx->stash->{num_runs};
    my @reqs = map makereq($ctx, GET => '/images'), 1 .. $num_runs;
    say "Sending $num_runs /images requests...";
    return sendreqs($ctx, @reqs);
}

func get_servers($ctx) {
    my $num_runs = $ctx->stash->{num_runs};
    my @reqs = map makereq($ctx, GET => '/servers'), 1 .. $num_runs;
    say "Sending $num_runs /servers requests...";
    return sendreqs($ctx, @reqs);
}

#---------- Helpers -----------------------------------------------------------

func makereq($ctx, $method, $resource, $body) {
    my $url = $ctx->stash->{base_url} . $resource;
    my $headers = $ctx->stash->{auth_headers};
    return HTTP::Request->new($method => $url, $headers, $body);
}

func sendreqs($ctx, @reqs) {
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

    if ($ctx->options->{verbose}) {
        foreach my $msg (@errmsgs) { warn "$msg\n" }
    }
    return "Successes: $successes Failures: $failures Time: " . runtime();
}

App::Rad->run();
