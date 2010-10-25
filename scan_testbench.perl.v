
`define SCAN_DELAY #1

module tbench();
   
   // Scan
   reg       scan_phi, scan_phi_bar, scan_data_in, scan_load_chip, scan_load_chain;
   wire      scan_data_out;

   //-----------------------------------------
   //  Scan Chain Registers and Tasks
   //-----------------------------------------

   // Scan Registers and Initializations
   
   PERL begin
      /*
       DEPERLIFY_INCLUDE(scan_signal_list.pl);
       
       print "`define SCAN_CHAIN_LENGTH $scan_chain_length\n\n";

       for (my $i = 0; $i < scalar @signal_list; $i++) {
       
          my $begin = 0;
          my $end   = $signal_list[$i]{size} - 1;

         print "   reg [$end:$begin] " . $signal_list[$i]{name} . ";\n";
         print "   reg [$end:$begin] " . $signal_list[$i]{name} . "_read;\n";
         print "   initial " . $signal_list[$i]{name} . " = " .$signal_list[$i]{size} . "'d0;\n";
         print "   initial " . $signal_list[$i]{name} . "_read = " .$signal_list[$i]{size} . "'d0;\n";
       }
       
       */
   end       

   // Scan chain tasks
   
   task load_chip;
      begin
         `SCAN_DELAY scan_load_chip = 1;
         `SCAN_DELAY scan_load_chip = 0;
      end
   endtask

   task load_chain;
      begin
         `SCAN_DELAY scan_load_chain = 1;
         `SCAN_DELAY scan_phi = 1;
         `SCAN_DELAY scan_phi = 0;
         `SCAN_DELAY scan_phi_bar = 1;
         `SCAN_DELAY scan_phi_bar = 0;
         `SCAN_DELAY scan_load_chain = 0;
      end
   endtask

   task rotate_chain;
      
      integer i;
      
      reg [`SCAN_CHAIN_LENGTH-1:0] data_in;
      reg [`SCAN_CHAIN_LENGTH-1:0] data_out;
      
      begin
         PERL begin
            /*
             DEPERLIFY_INCLUDE(scan_signal_list.pl);
             
             for (my $i = 0; $i < scalar @signal_list; $i++) {
             
                my $begin = $signal_list[$i]{start};
                my $end   = $signal_list[$i]{start} + $signal_list[$i]{size} - 1;
             
                print "         data_in[$end:$begin] = " . $signal_list[$i]{name} . ";\n";
             }
             
             */
         end 

         for (i = 0; i < `SCAN_CHAIN_LENGTH; i=i+1) begin
            scan_data_in = data_in[0];
            data_out     = {scan_data_out, data_out[`SCAN_CHAIN_LENGTH-1:1]};
            `SCAN_DELAY scan_phi = 1;
            `SCAN_DELAY scan_phi = 0;
            `SCAN_DELAY scan_phi_bar = 1;
            `SCAN_DELAY scan_phi_bar = 0;
            `SCAN_DELAY data_in = data_in >> 1;
         end

         PERL begin
            /*
             DEPERLIFY_INCLUDE(scan_signal_list.pl);
             
             for (my $i = 0; $i < scalar @signal_list; $i++) {
             
                my $begin = $signal_list[$i]{start};
                my $end   = $signal_list[$i]{start} + $signal_list[$i]{size} - 1;
             
                print "         " . $signal_list[$i]{name} . "_read = data_out[$end:$begin];\n";
             }
             
             */
         end 
      end
      
   endtask

   //-----------------------------------------
   //  Scan chain DUT
   //-----------------------------------------

   // We're going to use the name chip_iternal_<NAME> for the signals that would
   // normally be inside the chip that we're interacting with. We'll generate them
   // here

   PERL begin
      /*              
       DEPERLIFY_INCLUDE(scan_signal_list.pl);
       
       for (my $i = 0; $i < scalar @signal_list; $i++) {
           if ($signal_list[$i]{writable} == 1) {
                print "    wire ";
           } else {
                print "    reg  ";
           }
       
            print "[$signal_list[$i]{size}-1:0]  chip_internal_$signal_list[$i]{name};\n";
       }
       
       */
   end

   scan scan_dut ( // Inputs & outputs to the chip
             PERL begin
             /*              
              DEPERLIFY_INCLUDE(scan_signal_list.pl);
              
              for (my $i = 0; $i < scalar @signal_list; $i++) {
                 print "              .$signal_list[$i]{name}(chip_internal_$signal_list[$i]{name}),\n";
              }
              
              */
             end
             
                   // To the pads
                   .scan_phi        (scan_phi),
                   .scan_phi_bar    (scan_phi_bar),
                   .scan_data_in    (scan_data_in),
                   .scan_data_out   (scan_data_out),
                   .scan_load_chip  (scan_load_chip),
                   .scan_load_chain (scan_load_chain)
                   );
      
   
   //-----------------------------------------
   //  Testbench
   //-----------------------------------------
   
   initial begin

      $display("Starting scan chain test");
      
      scan_phi  = 0;
      scan_phi_bar = 0;
      scan_data_in = 0;
      scan_load_chip = 0;
      scan_load_chain = 0;  
      
      rotate_chain();      
      load_chip();

	  // Write each variable
      write_data_1 = 1'd1;
      write_data_2 = 2'd2;
      write_data_3 = 3'd3;

      rotate_chain();      
      load_chip();
      
      // Check that the chip sees the new variables
      if (chip_internal_write_data_1 != 1'd1 ||
          chip_internal_write_data_2 != 2'd2 ||
          chip_internal_write_data_3 != 3'd3 )
        $display("TEST 1 FAILED");
      else
        $display("TEST 1 PASSED");
         
      // Set internal values to read out      
      chip_internal_read_data_1 = 1'd0;  // As if the chip had this value internally
      chip_internal_read_data_2 = 2'd3;
      chip_internal_read_data_3 = 3'd5;

      // Read all of the values for both writable and non-writable variables
      load_chain();
      rotate_chain();

      // Check to see that we read out all values properly
      if (write_data_1_read != 1'd1 ||
          write_data_2_read != 2'd2 ||
          write_data_3_read != 3'd3 ||
          read_data_1_read  != 1'd0 ||
          read_data_2_read  != 2'd3 ||
          read_data_3_read  != 3'd5 ) begin
         $display("TEST 2 FAILED");
         $display("%d %d %d %d %d %d", 
                  write_data_1_read,
                  write_data_2_read,
                  write_data_3_read,
                  read_data_1_read,
                  read_data_2_read,
                  read_data_3_read);
      end else
        $display("TEST 2 PASSED");
        

      $finish;
   end

   //////////
   
endmodule // tbench

					  