use strict;
use warnings;

use Test::More tests => 9;
use Test::Deep;

{
    package DBIx::Class::Factory::Test::Schema::User;
    use base qw(DBIx::Class);

    __PACKAGE__->load_components('Core');
    __PACKAGE__->table('user');
    __PACKAGE__->add_columns(
        'id' => {
            data_type => 'integer',
            is_auto_increment => 1,
        },
        'name' => {
            data_type => 'varchar',
            size      => '100',
        },
        'comment' => {
            data_type   => 'varchar',
            size        => '100',
            is_nullable => 1,
        },
        'superuser' => {
            data_type => 'bool',
        },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(
        'user_languages' => 'DBIx::Class::Factory::Test::Schema::UserLanguage',
        'user_id'
    );
    __PACKAGE__->many_to_many('languages' => 'user_languages', 'languages');
}

{
    package DBIx::Class::Factory::Test::Schema::Language;
    use base qw(DBIx::Class);

    __PACKAGE__->load_components('Core');
    __PACKAGE__->table('language');
    __PACKAGE__->add_columns(
        'id' => {
            data_type => 'integer',
            is_auto_increment => 1,
        },
        'name' => {
            data_type => 'varchar',
            size      => '100',
        },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(
        'user_languages' => 'DBIx::Class::Factory::Test::Schema::UserLanguage',
        'language_id'
    );
    __PACKAGE__->many_to_many('users' => 'user_languages', 'users');
}

{
    package DBIx::Class::Factory::Test::Schema::UserLanguage;
    use base qw(DBIx::Class);

    __PACKAGE__->load_components('Core');
    __PACKAGE__->table('user_language');
    __PACKAGE__->add_columns(
        'id' => {
            data_type => 'integer',
            is_auto_increment => 1,
        },
        'user_id' => {
            data_type => 'integer',
        },
        'language_id' => {
            data_type => 'integer',
        },
        'level' => {
            data_type => 'integer',
        },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(
        'user' => 'DBIx::Class::Factory::Test::Schema::User',
        'user_id'
    );
    __PACKAGE__->belongs_to(
        'language' => 'DBIx::Class::Factory::Test::Schema::Language',
        'language_id'
    );
}

{
    package DBIx::Class::Factory::Test::Schema;
    use base qw(DBIx::Class::Schema);

    __PACKAGE__->load_classes('User', 'Language', 'UserLanguage',);
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
    package DBIx::Class::Factory::Test::LanguageFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset($schema->resultset('Language'));
    __PACKAGE__->fields({
        name => __PACKAGE__->seq(sub {'Language #' . shift}),
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
    package DBIx::Class::Factory::Test::CommentedUserFactory2;

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

$result = DBIx::Class::Factory::Test::LanguageFactory->create();
cmp_deeply(
    $schema->resultset('Language')->find($result->id),
    methods(name => 'Language #0'),
    'create (another factory)'
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
    [
        methods(name => 'User #7', superuser => 1),
        methods(name => 'User #8', superuser => 1),
    ],
    'create_batch'
);

$result = DBIx::Class::Factory::Test::CommentedUserFactory->create();
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(comment => 'User #9'),
    'create (with base factory)'
);

$result = DBIx::Class::Factory::Test::CommentedUserFactory2->create();
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(comment => 'COMMENT', name => 'NAME'),
    'create (with base factory, base_factory at the bottom)'
);

END {
    unlink('dbix-class-factory-test.sqlite');
}
