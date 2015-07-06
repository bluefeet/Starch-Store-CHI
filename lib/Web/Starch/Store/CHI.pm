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

This Starch store uses L<CHI> to set and get session data.

=head1 PERFORMANCE

When using CHI there are various choices you need to make:

=over

=item *

Which backend to use?  If data persistance is not an issue, or
you're using CHI as your outer store in L<Web::Starch::Store::Layered>
then Memcached or Redis are common solutions which have high
performance.

=item *

Which serializer to use?  Nowadays L<Sereal> is the serialization
performance heavweight, with L<JSON::XS> coming up a close second.

=item *

Which driver to use?  Some backends have more than one driver, and
some drivers perform better than others.  The most common example of
this is Memcached which has three drivers which can be used with
CHI.

=back

Make sure you ask these questions when you implement CHI for your
sessions, and take the time to answer them well.  It can make a big
difference.

=head1 CONSTRUCTOR

The arguments to this class are automatically shifted into the
L</chi> argument if the L</chi> argument is not specified. So,

    store => {
        class  => '::CHI',
        driver => 'Memory',
        global => 0,
    },

Is the same as:

    store => {
        class  => '::CHI',
        chi => {
            driver => 'Memory',
            global => 0,
        },
    },

Also, don't forget about method proxies which allow you to build
the L<CHI> object using your own code but still specify a static
configuration.  The below is equivelent to the previous two examples:

    package MyCHI;
    sub get_chi {
        my ($class) = @_;
        return CHI->new( driver=>'Memory', global=>0 );
    }

    store => {
        class  => '::CHI',
        chi => [ '&proxy', 'MyCHI', 'get_chi' ],
    },

You can read more about method proxies at
L<Web::Starch::Manual/METHOD PROXIES>.

=cut

use CHI;
use Types::Standard -types;
use Types::Common::String -types;
use Scalar::Util qw( blessed );

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
    $args->{max_expires} = delete( $chi->{max_expires} ) if exists $chi->{max_expires};

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

This must be set to either hash ref arguments for L<CHI> or a
pre-built CHI object (often retrieved using a method proxy).

When configuring Starch from static configuration files using a
method proxy is a good way to link your existing L<CHI> object
constructor in with Starch so that starch doesn't build its own.

=cut

has _chi_arg => (
    is       => 'ro',
    isa      => InstanceOf[ 'CHI::Driver' ] | HashRef,
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
    return $chi if blessed $chi;

    return CHI->new( %$chi );
}

=head1 STORE METHODS

See L<Web::Starch::Store> for more documentation about the methods
which all stores implement.

=cut

sub set {
    my ($self, $id, $data, $expires) = @_;

    $self->chi->set(
        $id,
        $data,
        $expires ? ($expires) : (),
    );

    return;
}

sub get {
    my ($self, $id) = @_;

    return $self->chi->get( $id );
}

sub remove {
    my ($self, $id) = @_;

    $self->chi->remove( $id );

    return;
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

