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

This starch store uses CHI to set and get session data.

=head1 CONSTRUCTOR

The arguments to this class are automatically shifted into the
L</chi> argument if the L</chi> argument is not specified. So,

    Web::Starch::Store::CHI->new(
        driver => 'Memory',
        global => 0,
    );

Is the same as:

    Web::Starch::Store::CHI->new(
        chi => {
            driver => 'Memory',
            global => 0,
        },
    );

Also, a method proxy array ref, as described in L</chi>, may
be passed to C<new>.  The below is equivelent to the previous
two examples:

    package MyCHI;
    sub get_chi {
        my ($class) = @_;
        return CHI->new( driver=>'Memory', global=>0 );
    }
    
    Web::Starch::Store::CHI->new(
        ['MyCHI', 'get_chi'],
    );

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

    if (@_ == 1 and ref($_[0]) eq 'ARRAY') {
        return { chi => $_[0] };
    }

    my $args = $self->$orig( @_ );
    $args = { chi => $args } if !exists $args->{chi};

    return $args;
};

=head1 REQUIRED ARGUMENTS

=head2 chi

Either arguments for L<CHI>, a pre-made L<CHI> object, or an array
ref containing a method proxy.

When specifying the method proxy the array ref looks like:

    [ $package, $method, @args ]

When configuring starch from static configuration files using a
method proxy is a good way to link your existing L<CHI> object
constructor in with starch so that starch doesn't build its own.

=cut

with qw(
    Web::Starch::Store
);

has _chi_arg => (
    is       => 'ro',
    isa      => HasMethods[ 'set', 'get', 'remove' ] | ArrayRef | HashRef,
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

    if (ref($chi) eq 'ARRAY') {
        my ($package, $method, @args) = @$chi;
        return $package->$method( @args );
    }

    return CHI->new( %$chi );
}

=head2 expiration

An expiration to specify when L</set> is called.  See C<set> in
L<CHI/Getting and setting> for possible values.

=cut

has expiration => (
    is => 'ro',
    isa => NonEmptySimpleStr | HashRef,
);

=head1 STORE METHODS

See L<Web::Starch::Store> for more documentation about the methods
which all stores implement.

=cut

sub set {
    my ($self, $id, $data) = @_;
    my $expiration = $self->expiration();
    $self->chi->set(
        $id,
        $data,
        defined($expiration) ? ($expiration) : (),
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
