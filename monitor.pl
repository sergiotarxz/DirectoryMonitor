#
# Copyright (C) 2019  Sergio Iglesias
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;
use feature qw(say);
use POSIX qw(strftime);
use Digest::file qw(digest_file);

my $dir = $ARGV[0] or die 'No file received';
-e $dir or die 'No such file';
-d $dir or die 'Not a dir';
my %files;
sub index_dir;
sub monitor {
    my $date = localtime;
    my $a = 0;
    my %old_hash = %files;
    my %changes;
    %files = ();
    index_dir $_[0];
    if (%old_hash) {
        for (keys %files) {
            $old_hash{$_} or do {$changes{$_} = 'Created'; next};
            $old_hash{$_} eq $files{$_} or $changes{$_} = 'Modified';
        }
        for (keys %old_hash) {
            $files{$_} or $changes{$_} = 'Removed';
        }
    }
    %changes and say strftime "%d/%m/%Y", localtime;
    for (keys %changes) {
        say "$changes{$_} $_";
    }
}
sub index_dir {
    my $path = "$_[0]";
    opendir(my $dh, $path);
    my @contents = readdir $dh;
    for (@contents) {
        my $file = "$path/$_";
        /^\.{1,2}$/ and next;
        $file =~ s/\/+/\//g;
        -f $file and $files{$file} = digest_file($file, 'MD5');
        -d $file and index_dir $file;
    }
    closedir $dh;
}
while (1) {
    sleep 0.5;
    monitor $ARGV[0];
}
