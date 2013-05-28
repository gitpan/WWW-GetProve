package WWW::GetProve::Verification;
BEGIN {
  $WWW::GetProve::Verification::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::GetProve::Verification::VERSION = '0.001';
}
# ABSTRACT: Verification response object


use Moo;
use DateTime;
use DateTime::Format::ISO8601;

for my $attr (qw( id tel country )) {
	has $attr => (
		is => 'ro',
		predicate => 1,
		coerce => sub { "$_[0]" },
	);
}

for my $attr (qw( test verified call text )) {
	has $attr => (
		is => 'ro',
		predicate => 1,
		coerce => sub { $_[0] ? 1 : 0 },
	);
}

for my $attr (qw( created updated )) {
	has $attr => (
		is => 'ro',
		predicate => 1,
		isa => sub {
			die $_[0]." need to be DateTime object (or an ISO8601 string that we coerce to it)" unless ref $_[0] && $_[0]->isa('DateTime')
		},
		coerce => sub {
			DateTime::Format::ISO8601->parse_datetime($_[0]) unless ref $_[0] && $_[0]->isa('DateTime')
		},
	);
}

1;
__END__
=pod

=head1 NAME

WWW::GetProve::Verification - Verification response object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

