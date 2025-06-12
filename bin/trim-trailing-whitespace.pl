#!/usr/bin/env perl

use strict;
use warnings;

# Process files passed as arguments or read from STDIN
if (@ARGV) {
    # Process each file passed as argument
    foreach my $file (@ARGV) {
        process_file($file);
    }
} else {
    # Process STDIN and output to STDOUT
    while (my $line = <STDIN>) {
        $line =~ s/\s+$//;
        print $line . "\n";
    }
}

sub process_file {
    my ($filename) = @_;
    
    # Read the file
    open(my $fh, '<', $filename) or die "Cannot open file '$filename': $!";
    my @lines = <$fh>;
    close($fh);
    
    # Trim trailing whitespace from each line
    my $modified = 0;
    for (my $i = 0; $i < @lines; $i++) {
        my $original = $lines[$i];
        $lines[$i] =~ s/\s+$//;
        $lines[$i] .= "\n" unless $lines[$i] eq '';
        $modified = 1 if $original ne $lines[$i];
    }
    
    # Write back only if modified
    if ($modified) {
        open($fh, '>', $filename) or die "Cannot write to file '$filename': $!";
        print $fh join('', @lines);
        close($fh);
        print "Trimmed trailing whitespace from: $filename\n";
    } else {
        print "No trailing whitespace found in: $filename\n";
    }
}