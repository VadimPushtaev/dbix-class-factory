use strict;
use warnings;

use Test::More tests => 4;
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

    sub resultset {
        $schema->resultset('User');
    }

    sub fields {
        name => __PACKAGE__->seq(sub {'User #' . shift}),
        superuser => 0,
    }
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
    methods(name => 'User #2', superuser => 0),
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

END {
    unlink('dbix-class-factory-test.sqlite');
}
