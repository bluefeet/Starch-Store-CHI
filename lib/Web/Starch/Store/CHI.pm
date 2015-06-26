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
        expires => 60 * 60 * 15, # 15 minutes
        ...,
    );

=head1 DESCRIPTION

This Starch store uses CHI to set and get session data.

=head1 CONSTRUCTOR

The arguments to this class are automatically shifted into the
L</chi> argument if the L</chi> argument is not specified. So,

    store => {
        class  => '::CHI',
        driver => 'Memory',
        global => 0,
        expires => 10 * 60, # 10 minutes
    },

Is the same as:

    store => {
        class  => '::CHI',
        chi => {
            driver => 'Memory',
            global => 0,
        },
        expires => 10 * 60, # 10 minutes
    },

Also, a method proxy array ref, as described in L</chi>, may
be passed.  The below is equivelent to the previous two examples:

    package MyCHI;
    sub get_chi {
        my ($class) = @_;
        return CHI->new( driver=>'Memory', global=>0 );
    }

    store => {
        class  => '::CHI',
        chi => ['MyCHI', 'get_chi'],
        expires => 10 * 60, # 10 minutes
    },

=cut

use CHI;
use Types::Standard -types;
use Types::Common::String -types;
use Scalar::Util qw( blessed );
use Module::Runtime qw( require_module );

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Store
);

around BUILDARGS => sub{
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig( @_ );
    return $args if exists $args->{chi};

    my $chi = $args;
    $args = { chi=>$chi };
    $args->{factory} = delete( $chi->{factory} );
    $args->{expires} = delete( $chi->{expires} );

    return $args;
};

sub BUILD {
  my ($self) = @_;

  # Get this loaded as early as possible.
  $self->chi();

  return;
}

=head1 REQUIRED ARGUMENTS

=head2 chi

This must be set to either hash ref arguments for L<CHI> or an array ref
containing a method proxy.

When specifying the method proxy the array ref looks like:

    [ $package, $method, @args ]

When configuring Starch from static configuration files using a
method proxy is a good way to link your existing L<CHI> object
constructor in with Starch so that starch doesn't build its own.

=cut

has _chi_arg => (
    is       => 'ro',
    isa      => ArrayRef | HashRef,
    init_arg => 'chi',
    required => 1,
);

has chi => (
    is       => 'lazy',
    isa      => InstanceOf[ 'CHI::Driver' ],
    init_arg => undef,
);
sub _build_chi {
    my ($self) = @_;

    my $chi = $self->_chi_arg();

    if (ref($chi) eq 'ARRAY') {
        my ($package, $method, @args) = @$chi;
        require_module( $package );
        return $package->$method( @args );
    }

    return CHI->new( %$chi );
}

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
        $expires ? ($expires) : (),
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
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

