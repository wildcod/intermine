package InterMine::Model;

=head1 NAME

InterMine::Model - the representation of an InterMine model

=head1 SYNOPSIS

  use InterMine::Model;
  use InterMine::ItemFactory;

  my $model_file = 'flymine/dbmodel/build/model/genomic_model.xml';
  my $model = new InterMine::Model(file => $model_file);
  my $factory = new InterMine::ItemFactory(model => $model);

  ...

=head1 DESCRIPTION

The class is the Perl representation of an InterMine data model.  The
new() method can parse the model file.  The
get_classdescriptor_by_name() method will return an
InterMine::Model::ClassDescriptor object for the class with the given
name.

For an example model see: 
http://trac.flymine.org/browser/trunk/intermine/objectstore/model/testmodel/testmodel_model.xml

=head1 AUTHOR

FlyMine C<< <support@flymine.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<support@flymine.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc InterMine::Model;

You can also look for information at:

=over 4

=item * FlyMine

L<http://www.flymine.org>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006,2007,2008,2009 FlyMine, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use strict;

=head2 new

 Title   : new
 Usage   : $model = new InterMine::Model(file => $model_file);
             or
           $model = new InterMine::Model(string => $model_string);
 Function: return a Model object for the given file
 Args    : file - the InterMine model XML file

=cut
sub new
{
  my $class = shift;
  my %opts = @_;
  my $self = {%opts};

  if (!defined $opts{file} && !defined $opts{string}) {
    die "$class\::new() needs a file or string argument\n";
  }
  elsif (defined $opts{file} && !-f $opts{file}) {
    die "A valid file must be specified: we got $opts{file}\n";
  }

  $self->{class_hash} = {};

  bless $self, $class;
  if (defined $opts{file}) {
    $self->_process($opts{file}, 0);
  } else {
    $self->_process($opts{string}, 1);
  }

  $self->_fix_class_descriptors();

  return $self;
}

use InterMine::Model::Attribute;
use InterMine::Model::Reference;
use InterMine::Model::Collection;
use InterMine::Model::ClassDescriptor;

package InterMine::Model::Handler;

use vars qw{ $AUTOLOAD };

sub new
{
  my $type = shift;
  my $self = ( $#_ == 0 ) ? shift : { @_ };

  return bless $self, $type;
}

sub start_element
{
  my $self = shift;
  my $args = shift;

  $self->{current_element} = $args->{Name};

  my $nameattr = $args->{Attributes}{name};

  if ($args->{Name} eq "model") {
    $self->{model}{model_name} = $nameattr;
    my $package_name = $args->{Attributes}{'package'};
    $self->{model}{package_name} = $package_name;
  } else {
    my $model = $self->{model};
    if ($args->{Name} eq "class") {
      my @extends = ();
      if (exists $args->{Attributes}{extends}) {
        @extends = split /\s+/, $args->{Attributes}{extends};
        @extends = grep { $_ ne 'java.lang.Object' } @extends;
        map { s/.*\.(.*)/$1/ } @extends;
      }
      $self->{current_class} =
        new InterMine::Model::ClassDescriptor(model => $model,
                                              name => $nameattr, extends => [@extends]);
    } else {
      my $field;
      if ($args->{Name} eq "attribute") {
        my $type = $args->{Attributes}{type};
        $field = InterMine::Model::Attribute->new(name => $nameattr,
                                                  type => $type,
                                                  model => $model);
      } else {
        my $referenced_type = $args->{Attributes}{'referenced-type'};
        my $reverse_reference = $args->{Attributes}{'reverse-reference'};
        if ($args->{Name} eq "reference") {
          $field = InterMine::Model::Reference->new(name => $nameattr,
                                                    referenced_type_name =>
                                                      $referenced_type,
                                                    reverse_reference_name =>
                                                      $reverse_reference,
                                                    model => $model);
        } else {
          if ($args->{Name} eq "collection") {
            $field = InterMine::Model::Collection->new(name => $nameattr,
                                                       referenced_type_name =>
                                                         $referenced_type,
                                                       reverse_reference_name =>
                                                         $reverse_reference,
                                                       model => $model);
          } else {
            die "unexpected element: ", $args->{Name}, "\n";
          }
        }
      }

      $field->field_class($self->{current_class});

      $self->{current_class}->add_field($field);
    }
  }
}

sub end_element {
  my $self = shift;
  my $args = shift;
  #  print "end_element: ", $args->{Name}, "\n";
  if ($args->{Name} eq 'class') {
    push @{$self->{classes}}, $self->{current_class};
    $self->{current_class} = undef;
  }
}

1;

package InterMine::Model;

use XML::Parser::PerlSAX;

sub _process
{
  my $self = shift;
  my $source_arg = shift;
  my $source_is_string = shift;

  my $handler = new InterMine::Model::Handler(model => $self);
  my $parser = XML::Parser::PerlSAX->new(Handler => $handler);

  my $source;

  if ($source_is_string) {
    $source = {String => $source_arg}; 
  } else {
    $source = {SystemId => $source_arg}; 
  }

  $parser->parse(Source => $source);

  $self->{classes} = $handler->{classes};

  for my $class (@{$self->{classes}}) {
    my $classname = $class->name();
    $self->{class_hash}{$classname} = $class;
  }
}

# add fields from base classes to sub-classes so that $class_descriptor->fields()
# returns fields from base classes too
sub _fix_class_descriptors
{
  my $self = shift;

  while (my ($class_name, $cd) = each %{$self->{class_hash}}){
    my @fields = $self->_get_fields($cd);
    for my $field (@fields) {
      $cd->add_field($field);
    }
  }
}

sub _get_fields
{
  my $self = shift;
  my $cd = shift;

  my @fields = ();

  for my $field ($cd->fields()) {
    my $field_name = $field->field_name();
    push @fields, $field;
  }

  my @extends = $cd->extends();

  for my $extendee_name (@extends) {
    my $extendee = $self->get_classdescriptor_by_name($extendee_name);

    push @fields, $self->_get_fields($extendee);
  }

  return @fields;
}

=head2 get_classdescriptor_by_name

 Title   : get_classdescriptor_by_name
 Usage   : $cd = $model->get_classdescriptor_by_name("Gene");
 Function: return the InterMine::Model::ClassDescriptor for the given class or
           undef if the class isn't in the model
 Args    : the classname

=cut
sub get_classdescriptor_by_name
{
  my $self = shift;
  my $classname = shift;

  if (!defined $classname) {
    die "no classname passed to get_classdescriptor_by_name()\n";
  }

  if (exists $self->{class_hash}{$classname}) {
    return $self->{class_hash}{$classname};
  } else {
    my $full_classname = $self->{package_name} . '.' . $classname;
    return $self->{class_hash}{$full_classname};
  }
}

=head2 get_all_classdescriptors

 Title   : get_all_classdescriptors
 Usage   : @cds = $model->get_all_classdescriptors();
 Function: return all the InterMine::Model::ClassDescriptor objects for this
           model
 Args    : none

=cut
sub get_all_classdescriptors
{
  my $self = shift;
  return values %{$self->{class_hash}};
}

=head2 package_name

 Title   : package_name
 Usage   : $package_name = $model->package_name();
 Function: return the package name derived from the name space
           eg. "org.intermine.model"
 Args    : none

=cut
sub package_name
{
  my $self = shift;
  return $self->{package_name};
}

=head2 model_name

 Title   : model_name
 Usage   : $model_name = $model->model_name();
 Function: return the model name from the model file eg. "testmodel"
 Args    : none

=cut
sub model_name
{
  my $self = shift;
  return $self->{model_name};
}

1;
