package DBIx::Class::Factory;

use 5.006;
use strict;
use warnings;

=head1 NAME

DBIx::Class::Factory - factory-style fixtures for DBIx::Class

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBIx::Class::Factory;

    my $foo = DBIx::Class::Factory->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS TO OVERRIDE

=cut

sub resultset {
    die;
}

sub fields {
    return;
}

=head1 METHODS TO USE INSIDE

=cut

sub seq {
    my ($class, $block) = @_;

    my $iter = 0;

    return sub {
        $block->($iter++);
    }
}
 
=head1 METHODS TO USE OUTSIDE

=cut

sub get_fields {
    my ($class, $extra_fields) = @_;

    $extra_fields = {} unless defined $extra_fields;

    our $_fields;
    unless (defined $_fields) {
        $_fields = {
            $class->maybe::next::method(),
            $class->fields,
        };
    }

    my $fields = {
        %{$_fields},
        %{$extra_fields}
    };

    return $class->_process_fields($fields);
}

sub build {
    my ($class, $extra_fields) = @_;

    return $class->resultset->new($class->get_fields($extra_fields));
}

sub create {
    my ($class, $extra_fields) = @_;

    return $class->build($extra_fields)->insert();
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

=head1 PRIVATE METHODS

=cut

sub _process_fields {
    my ($class, $fields) = @_;

    my $processed_fields = {};

    foreach my $key (keys %{$fields}) {
        my $value = $fields->{$key};
        $value = $value->() if ref($value) eq 'CODE';

        $processed_fields->{$key} = $value;
    }

    return $processed_fields;
}

sub _batch {
    my ($class, $method, $n, $extra_fields) = @_;

    my @batch = ();
    for (1 .. $n) {
        push(@batch, $class->$method($extra_fields));
    }

    return \@batch;
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
