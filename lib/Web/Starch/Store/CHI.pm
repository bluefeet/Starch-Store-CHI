package Web::Starch::Store::CHI;

=head1 NAME

Web::Starch::Store::CHI - Abstract.

=head1 DESCRIPTION

=cut

use Moo;
use strictures 1;
use namespace::clean;

with qw(
    Web::Starch::Store
);

=head1 STORE METHODS

See L<Web::Starch::Store> for more documentation about the methods
which all stores implement.

=cut

sub set {
    my ($self, $id, $data) = @_;
}

sub get {
    my ($self, $id) = @_;
}

sub remove {
    my ($self, $id) = @_;
}

1;
