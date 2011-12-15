package Net::OpenStack::Attack;
use strict;
use warnings;

# VERSION

use JSON qw(from_json to_json);
use LWP;
use Method::Signatures::Simple;

func auth($base_url) {
    $base_url =~ s{/$}{}; # Remove trailing slash if it exists
    my ($version) = $base_url =~ /(v\d\.\d)$/;
    return $version eq 'v1.1' ?
        auth_basic($base_url) : auth_keystone($base_url);
}

func auth_basic($base_url) {
    my $ua = LWP::UserAgent->new();
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
}

func auth_keystone($base_url) {
    my $ua = LWP::UserAgent->new();
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

# ABSTRACT: Steroids for your perl one-liners.

=head1 DESCRIPTION

This module contains helper methods used by stackattack.
You probably want to look at the documentation for L<stackattack> instead.

=cut

1;
