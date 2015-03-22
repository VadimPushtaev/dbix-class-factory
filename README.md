*This module is totally in development right now.*

DBIx::Class::Factory
-------------------

```perl
package My::UserFactory;     
                                                     
use base qw(DBIx::Class::Factory);                   
                                                     
__PACKAGE__->resultset(My::Schema->resultset('User'));  
__PACKAGE__->fields({                                
    name => __PACKAGE__->seq(sub {'User #' . shift}),
    superuser => 0,                                  
});                                                  
```

Ruby has `factory_girl`, Python has `factory_boy`.

Now Perl has `DBIx::Class::Factory`.
