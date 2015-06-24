package Web::Starch::Store::CHI;

=head1 NAME

Web::Starch::Store::CHI - Session storage backend using CHI.

=head1 SYNOPSIS

    my $starch = Web::Starch->new(
        store => {
            class => '::CHI',
            driver => 'File',
            root_dir => '/path/to/root',
        },
        ...,
    );

=head1 DESCRIPTION

=cut

use CHI;
use Types::Standard -types;
use Types::Common::String -types;
use Scalar::Util qw( blessed );

use Moo;
use strictures 1;
use namespace::clean;

around BUILDARGS => sub{
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig( @_ );

    $args = { chi => $args } if !exists $args->{chi};

    return $args;
};

=head1 REQUIRED ARGUMENTS

=head2 chi

=cut

with qw(
    Web::Starch::Store
);

has _chi_arg => (
    is       => 'ro',
    isa      => HasMethods[ 'set', 'get', 'remove' ] | HashRef,
    init_arg => 'chi',
    required => 1,
);

has chi => (
    is       => 'lazy',
    isa      => HasMethods[ 'set', 'get', 'remove' ],
    init_arg => undef,
);
sub _build_chi {
    my ($self) = @_;

    my $chi = $self->_chi_arg();
    return $chi if blessed $chi;

    return CHI->new( %$chi );
}

=head2 expires

=cut

has expires => (
    is => 'ro',
    isa => NonEmptySimpleStr | HashRef,
);

=head1 STORE METHODS

See L<Web::Starch::Store> for more documentation about the methods
which all stores implement.

=cut

sub set {
    my ($self, $id, $data) = @_;
    my $expires = $self->expires();
    $self->chi->set(
        $id,
        $data,
        defined($expires) ? ($expires) : (),
    );
}

sub get {
    my ($self, $id) = @_;
    return $self->chi->get( $id );
}

sub remove {
    my ($self, $id) = @_;
    return $self->chi->remove( $id );
}

1;
