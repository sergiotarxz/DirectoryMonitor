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
