

////////////////////////////////////////////////////////////////////////////////

module scan (

              // Inputs & outputs to the chip
             PERL begin
             /*              
              DEPERLIFY_INCLUDE(scan_signal_list.pl);
              
              for (my $i = 0; $i < scalar @signal_list; $i++) {
                 print "              $signal_list[$i]{name},\n";
              }
              
              */
             end
             
              // To the pads
              scan_phi,
              scan_phi_bar,
              scan_data_in,
              scan_data_out,
              scan_load_chip,
              scan_load_chain
             
              );

   
   // /////////////////////////////////////////////////////////////////////
   // Ports

   // Scans
   input   scan_phi;
   input   scan_phi_bar;
   input   scan_data_in;
   output  scan_data_out;
   input   scan_load_chain;
   input   scan_load_chip;

   
   PERL begin
      /*              
       DEPERLIFY_INCLUDE(scan_signal_list.pl);
       
       for (my $i = 0; $i < scalar @signal_list; $i++) {
           if ($signal_list[$i]{writable} == 1) {
                print "    output reg ";
           } else {
                print "    input      ";
           }
       
            print "[$signal_list[$i]{size}-1:0]  $signal_list[$i]{name};\n";
       }
       
       */
   end

   
   // /////////////////////////////////////////////////////////////////////
   // Implementation

   // The scan chain is comprised of two sets of latches: scan_master and scan_slave.
   
   PERL begin
      /*
       
       ##############################################################
       # Modify scan_signal_list.pl in order to change the signals. #
       ##############################################################
       
       DEPERLIFY_INCLUDE(scan_signal_list.pl);
       
       # Print scan chain latches
       print "   reg [$scan_chain_length-1:0] scan_master;\n";
       print "   reg [$scan_chain_length-1:0] scan_slave;\n\n";

       # Print scan_load and scan_next logic
       print "   wire [$scan_chain_length-1:0] scan_load;\n";
       print "   wire [$scan_chain_length-1:0] scan_next;\n\n";
       
       for (my $i = 0; $i < scalar @signal_list; $i++) {

          my $begin = $signal_list[$i]{start};
          my $end   = $signal_list[$i]{start} + $signal_list[$i]{size} - 1;
       
          print "   assign scan_load[$end:$begin] = " . $signal_list[$i]{name} . ";\n";
       }
       
       print "\n   assign scan_next = scan_load_chain ? scan_load : {scan_data_in, scan_slave[$'$scan_chain_length-1:1]};\n\n";
       
       # Print latches
       print "   //synopsys one_hot \"scan_phi, scan_phi_bar\"\n";
       print "   always @ (*) begin\n";
       print "       if (scan_phi)\n";
       print "          scan_master = scan_next;\n";
       print "       if (scan_phi_bar)\n";
       print "          scan_slave  = scan_master;\n";
       print "   end\n\n";
       
       # Print input latches
       for (my $i = 0; $i < scalar @signal_list; $i++) {
          if ($signal_list[$i]{writable} == 1) {
             my $begin = $signal_list[$i]{start};
             my $end   = $signal_list[$i]{start} + $signal_list[$i]{size} - 1;
             my $name  = $signal_list[$i]{name};
             print " always @ (*) if (scan_load_chip) $name = scan_slave[$end:$begin];\n";
          }
       }
       
       # Print data_out
       print "   assign scan_data_out = scan_slave[0];\n";
       
       */
   end

   
   // /////////////////////////////////////////////////////////////////////
   
endmodule
