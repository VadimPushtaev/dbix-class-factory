package DBIx::Class::Factory;

use strict;
use warnings;

use DBIx::Class::Factory::Fields;

=head1 NAME

DBIx::Class::Factory - factory-style fixtures for DBIx::Class

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01_TRIAL';

=head1 SYNOPSIS

{
    package My::UserFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset(My::Schema->resultset('User'));
    __PACKAGE__->fields({
        name => __PACKAGE__->seq(sub {'User #' . shift}),
        superuser => 0,
    });
}

# Creates users with 'User #0' .. 'User #3\6' names
My::UserFactory->create_batch(7, {status => 0});

=head1 DESCRIPTION

Creating the big fixtures batch may be a pain. This module provides easy way
of creating data in database via L<DBIx::Class>.

To create a factory just derive from L<DBIx::Class::Factory> and add some defaults.
You also can add some data at the moment of creating instance, redefining factory defaults.

Tests for this module contains a bunch of usefull examples.

=head1 METHODS TO CONSTRUCT FACTORY
=cut

=over

=item base_factory

Use this to create one factory derived from another. Don't user direct inheritance.

    {
        package My::UserFactory;

        use base qw(DBIx::Class::Factory);

        __PACKAGE__->resultset(My::Schema->resultset('User'));
        __PACKAGE__->fields({
            name => __PACKAGE__->seq(sub {'User #' . shift}),
            superuser => 0,
        });
    }

    {
        package My::SuperUserFactory;

        use base qw(DBIx::Class::Factory);

        __PACKAGE__->base_factory('My::UserFactory');
        __PACKAGE__->fields({
            superuser => 1,
        });
    }

=cut

sub base_factory {
    my ($class, $base_class) = @_;

    foreach my $data_field (qw(fields exclude)) {
        $class->_class_data->{$data_field} = {
            %{ $base_class->_class_data->{$data_field} || {} },
            %{ $class     ->_class_data->{$data_field} || {} },
        };
    }

    $class->_class_data->{resultset} = $base_class->_class_data->{resultset}
        unless defined $class->_class_data->{resultset};

    no strict 'refs';
    push(@{$class . '::ISA'}, $base_class);

    return;
}

sub resultset {
    my ($class, $resultset) = @_;

    $class->_class_data->{resultset} = $resultset;

    return;
}

sub fields {
    my ($class, $fields) = @_;

    foreach my $key (keys %{$fields}) {
        $class->field($key => $fields->{$key});
    }

    return;
}

sub field {
    my ($class, $key, $value) = @_;

    $class->_class_data->{fields}->{$key} = $value;

    return;
}

sub exclude {
    my ($class, $list) = @_;

    unless (ref $list eq 'ARRAY') {
        $list = [$list];
    }

    foreach my $exclude_field (@{$list}) {
        $class->_class_data->{exclude}->{$exclude_field} = 1;
    }

    return;
}

=head1 HELPERS

=cut

sub callback {
    my ($class, $block) = @_;

    return sub {
        $block->(@_);
    }
}

sub seq {
    my ($class, $block, $init_value) = @_;

    $init_value = 0 unless defined $init_value;

    return sub {
        $block->($init_value++, @_);
    }
}

sub related_factory {
    my ($class, $factory_class, $extra_fields) = @_;

    return sub {
        return $factory_class->get_fields($extra_fields);
    };
}

sub related_factory_batch {
    my ($class, $n, $factory_class, $extra_fields) = @_;

    return sub {
        return $factory_class->get_fields_batch($n, $extra_fields);
    };
}

=head1 METHODS TO USE OUTSIDE

=cut

sub get_fields {
    my ($class, $extra_fields) = @_;

    $extra_fields = {} unless defined $extra_fields;

    my $fields = DBIx::Class::Factory::Fields->new(
        {
            %{$class->_class_data->{fields}},
            %{$extra_fields},
        },
        $class->_class_data->{exclude}
    );

    return $class->after_get_fields($fields->all());
}

sub build {
    my ($class, $extra_fields) = @_;

    my $resultset = $class->_class_data->{resultset};
    die unless defined $resultset;

    return $class->after_build($resultset->new($class->get_fields($extra_fields)));
}


sub create {
    my ($class, $extra_fields) = @_;

    return $class->after_create($class->build($extra_fields)->insert());
}

sub get_fields_batch {
    my ($class, @params) = @_;

    return $class->_batch('get_fields', @params);
}

sub build_batch {
    my ($class, @params) = @_;

    return $class->_batch('build', @params);
}

sub create_batch {
    my ($class, @params) = @_;

    return $class->_batch('create', @params);
}

=head1 METHOD TO OVERRIDE

=cut

sub after_get_fields {
    my ($class, $fields) = @_;

    return $fields;
}

sub after_build {
    my ($class, $row) = @_;

    return $row;
}

sub after_create {
    my ($class, $row) = @_;

    return $row;
}

=head1 PRIVATE METHODS

=cut

sub _batch {
    my ($class, $method, $n, $extra_fields) = @_;

    my @batch = ();
    for (1 .. $n) {
        push(@batch, $class->$method($extra_fields));
    }

    return \@batch;
}

sub _class_data {
    my ($class) = @_;

    no strict 'refs';

    my $var_name = $class . '::class_data';

    unless (defined ${$var_name}) {
        ${$var_name} = {fields => {}}, 
    }

    return ${$var_name};
}

=head1 AUTHOR

Vadim Pushtaev, C<< <pushtaev at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-factory at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Factory>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Factory


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Factory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Factory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Factory>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Factory/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Vadim Pushtaev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DBIx::Class::Factory
