package Rex::Dondley::ProcessTaskArgs ;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = 'process_task_args';

# checks validity of args passed to functions and assigns them to appropriate keys
# Accept 3 sets of args:
# first arg is reference to parameters passed by user to task
# next set of args is a list of allowed params which can also indicate required params
# last arg is an array hash for default values corresponding to each allowed params
sub process_task_args {
  if (!$_[0] || (ref $_[0]) ne 'ARRAY') {
    die 'First argument must be an array ref to user supplied arguments.';
  }

  # standardize the argument data structure
  if (ref $_[0] && ref $_[0]->[0] ne 'HASH') {
    my @args = @{$_[0]};
    shift @_;
    @_ = ([ {}, \@args,], @_ );
  }

  my $passed_in     = shift @_;
  my %passed_params = %{$passed_in->[0]};
  my @unkeyed_args  = @{$passed_in->[1]};
  my @defaults      = ref $_[-1] ? @{$_[-1]} : ();
  my @valid_args    = @_;
  my @key_list      = grep { $_ && $_ ne '1' && (ref $_) ne 'ARRAY' } @_;

  my %defaults = ();
  my $count = 0;
  foreach my $key (@key_list) {
    $defaults{$key} = $defaults[$count++];
  }

  # create a hash of valid and required keys
  # assumes all values are not required if @valid_args do not contain required value
  my %valid_keys = ();
  if ((exists $valid_args[1] && ($valid_args[1] !~ /^0|1$/)) || scalar @valid_args == 1) { # checks to see if list contains required values
    foreach my $arg (@valid_args) {
      $valid_keys{$arg} = 0;
    }
  } else {
    use Data::Dumper qw(Dumper);
    print STDERR Dumper \@valid_args;
    %valid_keys = @valid_args;
  }

  # check to see if passed parameters are valid
  my @invalid_keys;
  foreach my $key (keys %passed_params) {
    my $is_valid = grep { $_ eq $key } keys %valid_keys;
    if (!$is_valid) {
      push @invalid_keys, $key;
    }
  die ("Invalid key(s): '" . join (', ', @invalid_keys) . "' from ". (caller)[1] . ', line ' . (caller)[2]) if @invalid_keys;
  }


  # Populate the %passed_params hash with @unkeyed_args according
  # to same order they were passed to this function via @valid_args.
  # Throw error if there are more args than available keys.
  if (@unkeyed_args) {
    my @all_array_args = @unkeyed_args;
    foreach my $array_arg (@unkeyed_args) {
      foreach my $vkey (@key_list) {
        if (exists $passed_params{$vkey}) {
          next;
        }
        $passed_params{$vkey} = $array_arg;
        shift @all_array_args;

        last;
      }
    }
    die ('Too many array arguments passed from ' . (caller)[1] . ', line ' . (caller)[2] ) if @all_array_args;

  }

  # Ensure required args are present
  my @reqd_keys     = grep { $valid_keys{$_} } keys %valid_keys;
  my @missing_keys;

  foreach my $rkey(@reqd_keys) {
    if (!exists $passed_params{$rkey} || $passed_params{$rkey} eq '1') {
      push @missing_keys, $rkey unless $defaults{$rkey};
    }
  }
  die ("Missing required key(s): '" . join (', ', @missing_keys) . "' from " . (caller)[1] . ', line ' . (caller)[2]) if @missing_keys;

  # handle edge case when user passes key without value
  foreach my $key (keys %passed_params) {
    if ($passed_params{$key} eq '1' && $valid_keys{$key}) {
      delete $passed_params{$key};
    }
  }
  my %return_hash = (%defaults, %passed_params);


  return \%return_hash;
}
# methods here

1; # Magic true value
# ABSTRACT: easier Rex task argument handling

__END__



=head1 OVERVIEW

Helper function for processing arguments passed to a Rex task.

=head1 SYNOPSIS

  use Rex::Dondley::ProcessTaskArgs;

  task 'some_task' => sub {
    # Process args passed to task
    my $params = process_task_args( \@_,                  # arguments passed by user
                                    available_key1 => 1,  # a required argument
                                    available_key2 => 0,  # an optional argument

                                    # optional array hash for default values
                                    [
                                      'default_value_for_key1',
                                      'default_value_for_key2',
                                    ]
                                  );

    # Now retrieve the values as usual
    my $key1 = $params->{key1};
    my $key2 = $params->{key2};
  };

  # If no arguments are required, list of available keys can be simplified:
  task 'another_task' => sub {
    my $params = process_task_args( \@_, key1, key2 [ 'default_value_for_key1' ]);
  };

=head1 DESCRIPTION

This module is designed to alleviate some of the pain of processing arguments
passed to tasks from the command line and from other tasks with the
C<run_task()> function. Think of it as a simpler, more specialized
version of L<Params::Validate>.

This module supplies a single function, C<process_task_args>, which accepts
three different types of arguments:

=over 1

=item * An array reference containing the original C<@_> special variable, followed
by...

=item * A list containing the available keys and, optionally, which keys are
required, followed by...

=item * An optional array reference containing the default values in the order
corresponding to the list of available keys

=back

C<process_task_args> does the following:

=over 1

=item * Ensures all required keys are given

=item * If arguments do not have associated keys on the command line, it will
assign them to the next avaiable key according to the order provided by the
available key list

=item * Replaces missing arguments with the default values, if provided

=item * Ensures no extra arguments are supplied

=item * Properly handles parameters passed via C<run_task()> as an array
C<run_task('some_task', params =E<gt> [ 'some_value' ]);>

=back

=head2 Special Edge Cases: Setting arguments to a value of 1 and using keys as switches

A special case exists if an argument is required and has a default value and you
are trying to set its value to "1". In such a case, your value will be
overridden if you supplied a default value for the key in your default values
argument.

To circumvent this unwanted behavior, you must make the key optional.
Alternatively, remove the default value from the default values array and
process the key manually.

Similarly, if you wish to use an argument as a switch, (i.e. setting a key
without a value with C<--some_key>), you must do the same.

=head2 Examples

=head3 Example #1

Given the following code:

  task 'another_task' => sub {
    my $params = process_task_args( \@_, key1, key2 [ 'default_value_for_key1' ] );
  };

And the following command line command:

  rex some_task

C<$params> will look like:

  $params = { key1 => 'default_value_for_key1', key2 => undef };

=head3 Example #2

Given the following code:

  task 'another_task' => sub {
    my $params = process_task_args( \@_, key1, key2 );
  };

And the following command line command:

  rex some_task some_value

C<$params> will look like:

  $params = { key1 => 'some_value', key2 => undef };

=head3 Example #3

Given the following code:

  task 'another_task' => sub {
    my $params = process_task_args( \@_, key1, key2 );
  };

And the following command line command:

  rex some_task some_value another_value

C<$params> will look like:

  $params = { key1 => 'some_value', key2 => another_value };

=head3 Example #4

Given the following code:

  task 'another_task' => sub {
    my $params = process_task_args( \@_, key1, key2 );
  };

And the following command line command:

  rex some_task some_value --key1=another_value

C<$params> will look like:

  $params = { key1 => 'another_value', key2 => 'some_value' };

=head3 Example #5

Given the following code:

  task 'another_task' => sub {
    my $params = process_task_args( \@_, key1 => 1, key2 => 1 );
  };

And the following command line command:

  rex some_task --key1=another_value

B<ERROR!> because C<key2> is required and it was not supplied.

=head1 FUNCTIONS

=function process_task_args($array_ref, $available_key1 [ => 1|0 ], $available_key2 [ => 1|0 ], ..., [ $array_ref ];
