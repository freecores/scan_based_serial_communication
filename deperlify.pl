 #!/usr/bin/perl

#################################################################################################
#
#  Copyright 2010 David Fick. All rights reserved.
#  
#  Redistribution and use in source and binary forms, with or without modification, are
#  permitted provided that the following conditions are met:
#  
#     1. Redistributions of source code must retain the above copyright notice, this list of
#        conditions and the following disclaimer.
#  
#     2. Redistributions in binary form must reproduce the above copyright notice, this list
#        of conditions and the following disclaimer in the documentation and/or other materials
#        provided with the distribution.
#  
#  THIS SOFTWARE IS PROVIDED BY DAVID FICK ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
#  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DAVID FICK OR
#  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
#  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#  
#  The views and conclusions contained in the software and documentation are those of the
#  authors and should not be interpreted as representing official policies, either expressed
#  or implied, of David Fick.
#
#################################################################################################


use strict;
use integer;

my $warning_verilog = "\n\n\n
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!    THIS IS A TEMPORARY FILE GENERATED BY DEPERILFY      !!
// !!             DO NOT MODIFY DIRECTLY!                     !!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
\n";

my $warning_io = "\n\n\n
#  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#  !!    THIS IS A TEMPORARY FILE GENERATED BY DEPERILFY      !!
#  !!             DO NOT MODIFY DIRECTLY!                     !!
#  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
\n";

sub max {
    my $a = shift;
    my $b = shift;

    return $a > $b ? $a : $b;
}


################################################################################################
# Grab Defines

my %defines;

sub grab_defines {

    my @params    = @_;
    my $file_name = $params[0];

    # Read the entire file
    my $file_contents;
    
    {
        local( $/, *FH ) ;
        open(FH, "< " . $file_name) or die "Failed to open \"". $file_name . "\" correctly.";
        $file_contents = <FH>;
        close(FH)
    }
    
    # Remove all comments
    $file_contents =~ s-//.*\n-\n-g;
    $file_contents =~ s-/\*.*\*/- -g;

    # Grab all of the defines
    while ($file_contents =~ /\`define\s+(\w+)[ \t]+([^\n]*)?\n/g) {
        
        my $macro      = $1;
        my $definition = $2;

        $defines{$macro} = $definition;
    }

    return;
}


################################################################################################
# Lookup Define

sub lookup {

    my $define     = shift;
    my $definition = $defines{$define};

    $definition = deep_replace($definition);

    return $definition ne "" ? $definition : "undef";
}

################################################################################################
# Deep Replace - replaces ` defines with their values

sub deep_replace {

    no integer;

    my $text   = shift;

    # Find and replace all defines
    $text =~ s-\`LG\(([^()]+?)\)-int(0.99999+log(eval(deep_replace($1)))/log(2))-ge;                # Special case for `LG macro
    $text =~ s-\`MAX\(([^()]+?),([^()]+?)\)-max(eval(deep_replace($1)),eval(deep_replace($2)))-ge;  # Special case for `MAX macro

    # Check for errors in the eval statement
    if ($@) {
        print "Error in perl section:\n" . $text . "\n ERRORS: \n" . $@;
        die;
    }

    # Do additional normal lookups
    $text =~ s/\`(\w+)/lookup($1)/ge;

    return $text;
}


################################################################################################
# Shallow Replace - replaces $` defines with their values

sub shallow_replace {

    my $text   = shift;

    # Find and replace all defines
    $text =~ s/\$\`(\w+)/lookup($1)/ge;
    
    return $text;
}


################################################################################################
# This function takes a string, executes it, and returns everything that was printed

sub execute_block {

    my $text           = shift;
    my $generated_text = "";

    # Inject the DEPERLIFY_INCLUDE files
    $text =~ s/DEPERLIFY_INCLUDE\(([^\)]+)\)/`cat $1`/gse;

    # Find and replace all defines
    $text = shallow_replace($text);

    # Execute the block of text that now has the generate statements
    # write perl code to a file
    my $temp_file = `mktemp deperlify.XXXXXXXXX`;
    chomp $temp_file;

    open (BLOCK_CODE, ">" . $temp_file);
    print BLOCK_CODE $text;
    # run perl on block
    $generated_text = `perl $temp_file`;
    `rm $temp_file`;

    # Check for errors in the eval statement
    if ($@) {
        print "Error in perl section:\n" . $text . "\n ERRORS: \n" . $@;
        die;
    }

    return $generated_text;
}


################################################################################################
# This function takes a file name and runs the program on that file

sub convert_file {

    my @params = @_;

    my $file_name        = $params[0];
    my $output_file_name = $file_name;

    $output_file_name =~ s/\.perl\./\./;
 
    # determine warning based on file type (determines type of comments used)
    my $warning;
    if ($file_name =~ /\.io/) {
        $warning = $warning_io;
    } else {
        $warning = $warning_verilog;
    }

    # Read the entire file
    my $file_contents;
    
    {
        local( $/, *FH ) ;
        open(FH, "< " . $file_name) or die "Failed to open \"". $file_name . "\" correctly";
        $file_contents = <FH>;
        close(FH)
    }

    # Do some operation
    $file_contents =~ s/[\t ]*PERL\s+begin\s+\/\*(.*?)\*\/\s+end\s*?\n/execute_block($1)/gse;

    $file_contents = $warning . $file_contents;

    # Write the entire file
    {
        local( *FH ) ;
        open(FH, "> " . $output_file_name) or die "Failed to write \"". $output_file_name . "\" correctly";
        print FH $file_contents;
        close(FH)
    }

}


################################################################################################
# Main code

foreach my $argnum (0 .. $#ARGV) {

    grab_defines($ARGV[$argnum]);

    if ($ARGV[$argnum] =~ /(\.perl\.v)|(\.perl\.io)/) {
        convert_file($ARGV[$argnum]);
    }
}


################################################################################################


