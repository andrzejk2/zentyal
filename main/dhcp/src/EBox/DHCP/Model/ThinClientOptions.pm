# Copyright (C) 2008-2013 Zentyal S.L.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Class: EBox::DHCP::Model::ThinClientOptions
#
# This class is the model to configurate thin client options for the dhcp
# server on a static interface. The fields are the following:
#
#     - next server, which tells dhcp client where to search the
#     terminal server
#
#     - filename, which indicates the firmware to load when the DHCP
#     client loads
#

use strict;
use warnings;

package EBox::DHCP::Model::ThinClientOptions;

use base 'EBox::Model::DataForm';

use feature 'switch';

use EBox::DHCP;
use EBox::DHCP::Types::Group;
use EBox::Exceptions::DataNotFound;
use EBox::Exceptions::External;
use EBox::Exceptions::InvalidData;
use EBox::Exceptions::MissingArgument;
use EBox::Gettext;
use EBox::Global;
use EBox::NetWrappers;
use EBox::Types::File;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::Host;
use EBox::Types::Select;
use EBox::Types::Boolean;
use EBox::Validate;
use EBox::View::Customizer;

# Group: Public methods

# Constructor: new
#
#     Create the thin client options to the dhcp server
#
# Overrides:
#
#     <EBox::Model::DataForm::new>
#
# Returns:
#
#     <EBox::DHCP::Model::ThinClientOptions>
#
# Exceptions:
#
#     <EBox::Exceptions::MissingArgument> - thrown if any compulsory
#     argument is missing
#
sub new
{
    my $class = shift;
    my %opts = @_;
    my $self = $class->SUPER::new(@_);
    bless ($self, $class);

    return $self;
}

# Method: nextServerIsZentyal
#
#     Finds out whether the next server the next server is Zentyal or not
#
# Parameters:
#
#     id - String the row identifier
#
# Returns:
#
#     Boolean - if Zentyal is the next server for the given row
#
# Exceptions:
#
#     <EBox::Exceptions::DataNotFound> - thrown if the given id is not
#     from this model
#
sub nextServerIsZentyal
{
    my ($self, $id) = @_;

    my $row = $self->row();

    unless ( defined($row) ) {
        throw EBox::Exceptions::DataNotFound(data => 'id', value => $id);
    }

    return ( $row->valueByName('nextServer') eq 'nextServerEBox' );

}

# Method: nextServer
#
#     Get the next server (name or IP address) in an string form to
#     tell the DHCP clients which is the next server to ask for
#     terminal
#
# Parameters:
#
#     id - String the row identifier
#
# Returns:
#
#     String - a name or an IP address
#
# Exceptions:
#
#     <EBox::Exceptions::DataNotFound> - thrown if the given id is not
#     from this model
#
sub nextServer
{
    my ($self, $id) = @_;

    my $row = $self->row();

    unless ( defined($row) ) {
        throw EBox::Exceptions::DataNotFound(data => 'id', value => $id);
    }

    return $row->valueByName('nextServerHost');
}

# Method: remoteFilename
#
#   Get the remote filename in an string form to tell the DHCP clients which
#   is the file to ask for to the server
#
# Parameters:
#
#     id - String the row identifier
#
# Returns:
#
#     String - a filename
#
# Exceptions:
#
#     <EBox::Exceptions::DataNotFound> - thrown if the given id is not
#     from this model
#
sub remoteFilename
{
    my ($self, $id) = @_;

    my $row = $self->row();

    unless (defined($row)) {
        throw EBox::Exceptions::DataNotFound(data => 'id', value => $id);
    }

    my $nextServerType = $row->valueByName('nextServer');
    given ($nextServerType) {
        when ('nextServerHost') {
            return $row->valueByName('remoteFilename');
        }
        default {
            return '';
        }
    }
}

# Group: Protected methods

# Method: _table
#
# Overrides:
#
#     <EBox::Model::DataForm::_table>
#
sub _table
{
    my ($self) = @_;

    my @tableDesc = (
        new EBox::Types::Union(
                              fieldName     => 'nextServer',
                              printableName => __('Next server'),
                              editable      => 1,
                              subtypes      => [
                                new EBox::Types::Union::Text(fieldName     => 'nextServerEBox',
                                                             printableName => __('Zentyal'),
                                                           ),
                                new EBox::Types::Host(fieldName => 'nextServerHost',
                                                     printableName => __('Host'),
                                                     editable => 1,
                                                     help          => __('Thin Client server as seen by the clients.'),
                                ),
                             ],
        ),
        new EBox::Types::Text(
                             fieldName     => 'remoteFilename',
                             printableName => __('File path'),
                             editable      => 1,
                             optional      => 1,
                             help          => __('Thin client file path'),
                            ),
    );

    # FIXME: unhardcode this (parentRow() is undefined)
    my $interface = 'eth0';

    my $dataTable = {
                    tableName          => 'ThinClientOptions',
                    printableTableName => __('Thin client'),
                    modelDomain        => 'DHCP',
                    defaultActions     => [ 'add', 'del', 'editField', 'changeView' ],
                    tableDescription   => \@tableDesc,
                    class              => 'dataTable',
                    help               => __x('You may want to customise your thin client options.'
                                             . 'To do so, you may include all the files you require '
                                             . 'under {path} directory',
                                             path => EBox::DHCP->PluginConfDir($interface)),
                    sortedBy           => 'hosts',
                    printableRowName   => __('thin client option'),
                   };

    return $dataTable;
}

1;
