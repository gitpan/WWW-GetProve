package WWW::GetProve;
BEGIN {
  $WWW::GetProve::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::GetProve::VERSION = '0.001';
}
# ABSTRACT: Easy access to the already so easy GetProve API


use MooX qw(
	+LWP::UserAgent
	+HTTP::Request::Common
	+URI
	+URI::QueryParam
	+JSON
	+WWW::GetProve::Verification
);


use Carp qw( croak );

our $VERSION ||= '0.000';


has api_key => (
	is => 'ro',
	required => 1,
);


has base_uri => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_base_uri { 'https://getprove.com/api/v1' }


has useragent => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_useragent {
	my ( $self ) = @_;
	my $useragent = LWP::UserAgent->new(
		agent => $self->useragent_agent,
		$self->has_useragent_timeout ? (timeout => $self->useragent_timeout) : (),
	);
	my $host_port = URI->new($self->base_uri)->host_port;
	$useragent->credentials(
		$host_port,"Authorization Required",$self->api_key,"1"
	);
	return $useragent;
}


has useragent_agent => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_useragent_agent { (ref $_[0] ? ref $_[0] : $_[0]).'/'.$VERSION }


has useragent_timeout => (
	is => 'ro',
	predicate => 'has_useragent_timeout',
);


has json => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_json {
	my $json = JSON->new;
	$json->allow_nonref;
	return $json;
}

#############################################################################################################

sub BUILDARGS {
	my ( $class, @args ) = @_;
	unshift @args, "api_key" if @args % 2 && ref $args[0] ne 'HASH';
	return { @args };
}

sub make_url {
	my ( $self, @args ) = @_;
	my $url = join('/',$self->base_uri,@args);
	my $uri = URI->new($url);
	return $uri;
}

sub create_verification {
	my $self = shift;
	my %args;
	$args{id} = shift unless (scalar @_ % 2);
	%args = %{@_};
	WWW::GetProve::Verification->new(%args);
}

sub verify_request {
	my ( $self, $tel_or_verification, $pin ) = @_;
	if (ref $tel_or_verification) {
		my $id;
		if (ref $tel_or_verification eq 'SCALAR') {
			$id = ${$tel_or_verification};
		} elsif ($tel_or_verification->isa('WWW::GetProve::Verification')) {
			$id = $tel_or_verification->id;
		}
		if ($pin) {
			POST(shift->make_url('verify', $id, 'pin'), [ pin => $pin ])
		} else {
			GET(shift->make_url('verify', $id))
		}
	} elsif ($tel_or_verification) {
		POST($self->make_url('verify'), [ tel => $tel_or_verification ])
	} else {
		GET($self->make_url('verify'))
	}
}

sub verify {
	my ( $self, @args ) = @_;
	my $request = $self->verify_request(@args);
	my $response = $self->useragent->request($request);
	die __PACKAGE__." API server says unauthorized access" if $response->code == 401;
	my $data = $self->json->decode($response->content);
	if (ref $data eq 'ARRAY') {
		my @verifications = map {
			WWW::GetProve::Verification->new($_);
		} @{$data};
		return wantarray ? @verifications : \@verifications;
	} else {
		return WWW::GetProve::Verification->new($data);
	}
}

1;


__END__
=pod

=head1 NAME

WWW::GetProve - Easy access to the already so easy GetProve API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $getprove = WWW::GetProve->new($authy_api_key);

  my @verifications = $getprove->verifications;
  my $verifications_as_arrayref = $getprove->verifications;

=head1 DESCRIPTION

This library gives an easy way to access the API of L<GetProve|https://www.getprove.com/>
to verify phone numbers with voice and SMS.

=head1 ATTRIBUTES

=head2 api_key

API Key for the account given on the Account Settings

=head2 base_uri

Base of the URL of the Authy API, this is B<https://api.authy.com> without
sandbox mode, and B<http://sandbox-api.authy.com>, when the sandbox is
activated.

=head2 useragent

L<LWP::UserAgent> object used for the HTTP requests.

=head2 useragent_agent

The user agent string used for the L</useragent> object.

=head2 useragent_timeout

The timeout value in seconds used for the L</useragent> object, defaults to default value of
L<LWP::UserAgent>.

=head2 json

L<JSON> object used for JSON decoding.

=head1 SUPPORT

IRC

  Join #getprove on irc.freenode.net

Repository

  http://github.com/getprove/prove-perl
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/getprove/prove-perl/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

