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
    my ($self, $fields, $exclude_set) = @_;

    $self->{init_fields} = $fields;
    $self->{processed_fields} = {};
    $self->{exclude_set} = $exclude_set;

    return;
}

sub all {
    my ($self) = @_;

    my %result;
    foreach my $field (keys %{$self->{init_fields}}) {
        unless (defined $self->{exclude_set}->{$field}) {
            $result{$field} = $self->get($field);
        }
    }

    return \%result;
}

sub get {
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
