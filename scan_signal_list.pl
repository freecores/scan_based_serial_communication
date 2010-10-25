

# The list at the beginning defines the scan lists. Defining an input name or output
#                                    name determines what type of scan signal it is.

# Values are always readable (the buffering latch is what is read if writable)

my @signal_list = ( # Inputs - outside to chip
                    { size =>   1, writable => 1, name => 'write_data_1'},
                    { size =>   2, writable => 1, name => 'write_data_2'},
                    { size =>   3, writable => 1, name => 'write_data_3'},

                    # Outputs - chip to outside
                    { size =>   1, writable => 0, name => 'read_data_1'},
                    { size =>   2, writable => 0, name => 'read_data_2'},
                    { size =>   3, writable => 0, name => 'read_data_3'},
                    );

my $scan_chain_length = 0;

for (my $i = 0; $i < scalar @signal_list; $i++) {
    $signal_list[$i]{start} = $scan_chain_length;
    $scan_chain_length += $signal_list[$i]{size};
}
