use strict;
use warnings;

use Test::More tests => 10;
use Test::Deep;

{
    package DBIx::Class::Factory::Test::Schema::User;
    use base qw(DBIx::Class);

    __PACKAGE__->load_components('Core');
    __PACKAGE__->table('user');
    __PACKAGE__->add_columns(
        id => {
            data_type => 'integer',
            is_auto_increment => 1,
        },
        name => {
            data_type => 'varchar',
            size      => '100',
        },
        comment => {
            data_type   => 'varchar',
            size        => '100',
            is_nullable => 1,
        },
        superuser => {
            data_type => 'bool',
        },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(
        accounts => 'DBIx::Class::Factory::Test::Schema::Account',
        'user_id'
    );
}

{
    package DBIx::Class::Factory::Test::Schema::Account;
    use base qw(DBIx::Class);

    __PACKAGE__->load_components('Core');
    __PACKAGE__->table('city');
    __PACKAGE__->add_columns(
        id => {
            data_type => 'integer',
            is_auto_increment => 1,
        },
        sum => {
            data_type => 'integer',
        },
        user_id => {
            data_type => 'integer',
        },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(
        user => 'DBIx::Class::Factory::Test::Schema::User',
        'user_id'
    );
}



{
    package DBIx::Class::Factory::Test::Schema;
    use base qw(DBIx::Class::Schema);

    __PACKAGE__->load_classes('User', 'Account');
}

my $schema = DBIx::Class::Factory::Test::Schema->connect(
    'dbi:SQLite:dbname=dbix-class-factory-test.sqlite', '', ''
);

{
    package DBIx::Class::Factory::Test::UserFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset($schema->resultset('User'));
    __PACKAGE__->fields({
        name => __PACKAGE__->seq(sub {'User #' . shift}),
        superuser => 0,
    });
}

{
    package DBIx::Class::Factory::Test::AccountFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset($schema->resultset('Account'));
    __PACKAGE__->fields({
        user => __PACKAGE__->related_factory('DBIx::Class::Factory::Test::UserFactory'),
        sum => 0,
    });
}

{
    package DBIx::Class::Factory::Test::UserWithTwoAccountsFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->base_factory('DBIx::Class::Factory::Test::UserFactory');
    __PACKAGE__->fields({
        accounts => __PACKAGE__->related_factory_batch(
            2, 'DBIx::Class::Factory::Test::AccountFactory',
            {user => {}}, # negate parent 'user => ...'
        ),
    });
}

{
    package DBIx::Class::Factory::Test::CommentedUserFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->base_factory('DBIx::Class::Factory::Test::UserFactory');
    __PACKAGE__->fields({
        comment => sub {shift->get_field('name')},
    });
}

{
    package DBIx::Class::Factory::Test::CommentedUserFactoryBot;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->fields({
        name    => 'NAME',
        comment => 'COMMENT',
    });

    # at the bottom
    __PACKAGE__->base_factory('DBIx::Class::Factory::Test::CommentedUserFactory'); 
}

$schema->deploy();

my $result;

$result = DBIx::Class::Factory::Test::UserFactory->get_fields();
cmp_deeply(
    $result,
    {name => 'User #0', superuser => 0},
    'get_fields'
);

$result = DBIx::Class::Factory::Test::UserFactory->build({superuser => 1});
cmp_deeply(
    $result,
    methods(name => 'User #1', superuser => 1),
    'build'
);

$result = DBIx::Class::Factory::Test::UserFactory->create();
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(name => 'User #2'),
    'create'
);

$result = DBIx::Class::Factory::Test::UserFactory->get_fields_batch(2, {superuser => 1});
cmp_deeply(
    $result,
    [
        {name => 'User #3', superuser => 1},
        {name => 'User #4', superuser => 1},
    ],
    'get_fields_batch'
);

$result = DBIx::Class::Factory::Test::UserFactory->build_batch(2);
cmp_deeply(
    $result,
    [
        methods(name => 'User #5', superuser => 0),
        methods(name => 'User #6', superuser => 0),
    ],
    'build_batch'
);

$result = DBIx::Class::Factory::Test::UserFactory->create_batch(2, {superuser => 1});
cmp_deeply(
    [
        $schema->resultset('User')->search({
            id => [map {$_->id} @{$result}]
        })->all()
    ],
    bag(
        methods(name => 'User #7', superuser => 1),
        methods(name => 'User #8', superuser => 1),
    ),
    'create_batch'
);

$result = DBIx::Class::Factory::Test::CommentedUserFactory->create();
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(comment => 'User #9'),
    'create (with base factory)'
);

$result = DBIx::Class::Factory::Test::CommentedUserFactoryBot->create({name => 'FOO'});
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(comment => 'COMMENT', name => 'FOO'),
    'create (with base factory, base_factory at the bottom)'
);

$result = DBIx::Class::Factory::Test::AccountFactory->create();
cmp_deeply(
    $schema->resultset('User')->find($result->user_id),
    methods(name => 'User #10'),
    'related_factory helper'
);

$result = DBIx::Class::Factory::Test::UserWithTwoAccountsFactory->create();
cmp_deeply(
    $result->accounts->count,
    2,
    'related_factory_batch helper'
);

END {
    unlink('dbix-class-factory-test.sqlite');
}
