package DBIx::Class::Factory::Fields;

use strict;
use warnings;

=head1 NAME

DBIx::Class::Factory::Fields - fields for DBIx::Class::Factory class

=cut

sub new {
    my ($class, @params) = @_;

    my $instance = bless({}, $class);
    $instance->init(@params);

    return $instance;
}

sub init {
    my ($self, $fields) = @_;

    $self->{init_fields} = $fields;
    $self->{processed_fields} = {};

    return;
}

sub all {
    my ($self) = @_;

    my %result;
    foreach my $field (keys %{$self->{init_fields}}) {
        $result{$field} = $self->get_field($field);
    }

    return \%result;
}

sub get_field {
    my ($self, $field) = @_;

    unless (exists $self->{processed_fields}->{$field}) {
        my $value = $self->{init_fields}->{$field};
    
        if (ref($value) eq 'CODE') {
            $value = $value->($self);
        }

        $self->{processed_fields}->{$field} = $value;
    }

    return $self->{processed_fields}->{$field};
}

1;
