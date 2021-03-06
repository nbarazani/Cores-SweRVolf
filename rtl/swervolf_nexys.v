// SPDX-License-Identifier: Apache-2.0
// Copyright 2019 Western Digital Corporation or its affiliates.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//********************************************************************************
// $Id$
//
// Function: SweRVolf toplevel for Nexys A7 board
// Comments:
//
//********************************************************************************

`default_nettype none
module swervolf_nexys_a7
  #(parameter bootrom_file = "bootloader.vh")
   (input wire 	       clk,
    input wire 	       rstn,
    output wire [12:0] ddram_a,
    output wire [2:0]  ddram_ba,
    output wire        ddram_ras_n,
    output wire        ddram_cas_n,
    output wire        ddram_we_n,
    output wire        ddram_cs_n,
    output wire [1:0]  ddram_dm,
    inout wire [15:0]  ddram_dq,
    inout wire [1:0]  ddram_dqs_p,
    inout wire [1:0]  ddram_dqs_n,
    output wire        ddram_clk_p,
    output wire        ddram_clk_n,
    output wire        ddram_cke,
    output wire        ddram_odt,
    output wire        o_flash_cs_n,
    output wire        o_flash_mosi,
    input wire 	       i_flash_miso,
    input wire 	       i_uart_rx,
    output wire        o_uart_tx,
    input wire [15:0]  i_sw,
    output reg [15:0]  o_led,
    output reg [7:0] an,
    output reg ca,
    output reg cb,
    output reg cc,
    output reg cd,
    output reg ce,
    output reg cf,
    output reg cg);

   wire [63:0] 	       gpio_out;
   reg [15:0] 	       led_int_r;

   reg [15:0] 	       sw_r;
   reg [15:0] 	       sw_2r;

   wire 	       cpu_tx,litedram_tx;

   wire 	       litedram_init_done;
   wire 	       litedram_init_error;

   localparam RAM_SIZE     = 32'h10000;

   wire 	 clk_core;
   wire 	 rst_core;
   wire 	 user_clk;
   wire 	 user_rst;
   
     //NIBA
   wire [31:0] branches_counter;
   wire [31:0] branches_taken_counter;
   
   reg [6:0] seven_seg;
   
   Seven_seg(clk, seven_seg, an, branches_counter, branches_taken_counter, sw_2r[1]); 
	
module Seven_seg(CLK, SSEG_CA, SSEG_AN, branches_counter, branches_taken_counter, switch);

    input wire CLK;
    input wire [31:0] branches_counter;
    input wire [31:0] branches_taken_counter;
    output reg [6:0] SSEG_CA;
    output reg [7:0] SSEG_AN;
    input wire switch;
	
    reg Clk_Slow;
    reg [31:0] value;
	
    slow_clock S1 (CLK, Clk_Slow);          //initializes clock
    reg [3:0] four_bits;
	
	
    initial begin
        SSEG_AN <= 8'b11111110;             //start at first anode
    end
	
	
    always @(*) begin
	    if (!switch) begin
		    value = branches_counter;
	    end
	    else begin
		    value = branches_taken_counter;
	    end
    end
	
	
    always @ (posedge Clk_Slow)
    begin
	    case (four_bits)
		4'b0000 : begin SSEG_CA = 7'b0000001; end
		4'b0001 : begin SSEG_CA = 7'b1001111; end	
		4'b0010 : begin SSEG_CA = 7'b0010010; end
		4'b0011 : begin SSEG_CA = 7'b0000110; end
		4'b0100 : begin SSEG_CA = 7'b1001100; end
		4'b0101 : begin SSEG_CA = 7'b0100100; end
		4'b0110 : begin SSEG_CA = 7'b0100000; end
		4'b0111 : begin SSEG_CA = 7'b0001111; end
		4'b1000 : begin SSEG_CA = 7'b0000000; end
		4'b1001 : begin SSEG_CA = 7'b0000100; end
		4'b1010 : begin SSEG_CA = 7'b0001000; end
		4'b1011 : begin SSEG_CA = 7'b1100000; end
		4'b1100 : begin SSEG_CA = 7'b0110001; end
		4'b1101 : begin SSEG_CA = 7'b1000010; end	
		4'b1110 : begin SSEG_CA = 7'b0110000; end
		4'b1111 : begin SSEG_CA = 7'b0111000; end
		default : begin SSEG_CA = 7'b1111111; end
        endcase

        case (SSEG_AN)
		8'b10111111: begin SSEG_AN <= 8'b01111111; four_bits[3:0] <= value[3:0]; /*4'b0000; */ end
		8'b01111111: begin SSEG_AN <= 8'b11111110; four_bits[3:0] <= value[7:4]; /*4'b0001; */ end
		8'b11111110: begin SSEG_AN <= 8'b11111101; four_bits[3:0] <= value[11:8]; /*4'b0010; */ end
		8'b11111101: begin SSEG_AN <= 8'b11111011; four_bits[3:0] <= value[15:12]; /*4'b0011; */ end
		8'b11111011: begin SSEG_AN <= 8'b11110111; four_bits[3:0] <= value[19:16]; /*4'b0100; */ end
		8'b11110111: begin SSEG_AN <= 8'b11101111; four_bits[3:0] <= value[23:20]; /*4'b0101; */ end
		8'b11101111: begin SSEG_AN <= 8'b11011111; four_bits[3:0] <= value[27:24]; /*4'b0110; */ end
		8'b11011111: begin SSEG_AN <= 8'b10111111; four_bits[3:0] <= value[31:28]; /*4'b0111; */ end
        endcase
    end
endmodule   
//SLOW CLK	
module slow_clock(CLK, Clk_Slow);
    input wire CLK;
    output reg Clk_Slow;

    reg [31:0] counter_out; 
	
initial begin 
   counter_out<=32'h00000000; 
   Clk_Slow<=0; 
end 

//this always block runs on the fast 100MHz clock

    always @(posedge CLK) begin 
   counter_out<=counter_out + 32'h00000001; 
   if (counter_out>32'h0000E100) begin 
       counter_out<=32'h00000000; 
       Clk_Slow<=!Clk_Slow; 
   end 
end
endmodule

always @(*) begin
	ca = seven_seg[6];
	cb = seven_seg[5];
	cc = seven_seg[4];
	cd = seven_seg[3];
	ce = seven_seg[2];
	cf = seven_seg[1];
	cg = seven_seg[0];	
end
   //NIBA

   clk_gen_nexys clk_gen
     (.i_clk (user_clk),
      .i_rst (user_rst),
      .o_clk_core (clk_core),
      .o_rst_core (rst_core));

   AXI_BUS #(32, 64, 6, 1) mem();
   AXI_BUS #(32, 64, 6, 1) cpu();

   assign cpu.aw_atop = 6'd0;
   assign cpu.aw_user = 1'b0;
   assign cpu.ar_user = 1'b0;
   assign cpu.w_user = 1'b0;
   assign cpu.b_user = 1'b0;
   assign cpu.r_user = 1'b0;
   assign mem.b_user = 1'b0;
   assign mem.r_user = 1'b0;

   axi_cdc_intf
     #(.AXI_USER_WIDTH (1),
       .AXI_ADDR_WIDTH (32),
       .AXI_DATA_WIDTH (64),
       .AXI_ID_WIDTH   (6))
   cdc
     (
      .src_clk_i  (clk_core),
      .src_rst_ni (~rst_core),
      .src        (cpu),
      .dst_clk_i  (user_clk),
      .dst_rst_ni (~user_rst),
      .dst        (mem));

   litedram_top
     #(.ID_WIDTH (6))
   ddr2
     (.serial_tx   (litedram_tx),
      .serial_rx   (i_uart_rx),
      .clk100      (clk),
      .rst_n       (rstn),
      .pll_locked  (),
      .user_clk    (user_clk),
      .user_rst    (user_rst),
      .ddram_a     (ddram_a),
      .ddram_ba    (ddram_ba),
      .ddram_ras_n (ddram_ras_n),
      .ddram_cas_n (ddram_cas_n),
      .ddram_we_n  (ddram_we_n),
      .ddram_cs_n  (ddram_cs_n),
      .ddram_dm    (ddram_dm   ),
      .ddram_dq    (ddram_dq   ),
      .ddram_dqs_p (ddram_dqs_p),
      .ddram_dqs_n (ddram_dqs_n),
      .ddram_clk_p (ddram_clk_p),
      .ddram_clk_n (ddram_clk_n),
      .ddram_cke   (ddram_cke  ),
      .ddram_odt   (ddram_odt  ),
      .init_done  (litedram_init_done),
      .init_error (litedram_init_error),
      .i_awid    (mem.aw_id   ),
      .i_awaddr  (mem.aw_addr[26:0] ),
      .i_awlen   (mem.aw_len  ),
      .i_awsize  ({1'b0,mem.aw_size} ),
      .i_awburst (mem.aw_burst),
      .i_awvalid (mem.aw_valid),
      .o_awready (mem.aw_ready),
      .i_arid    (mem.ar_id   ),
      .i_araddr  (mem.ar_addr[26:0] ),
      .i_arlen   (mem.ar_len  ),
      .i_arsize  ({1'b0,mem.ar_size} ),
      .i_arburst (mem.ar_burst),
      .i_arvalid (mem.ar_valid),
      .o_arready (mem.ar_ready),
      .i_wdata   (mem.w_data  ),
      .i_wstrb   (mem.w_strb  ),
      .i_wlast   (mem.w_last  ),
      .i_wvalid  (mem.w_valid ),
      .o_wready  (mem.w_ready ),
      .o_bid     (mem.b_id    ),
      .o_bresp   (mem.b_resp  ),
      .o_bvalid  (mem.b_valid ),
      .i_bready  (mem.b_ready ),
      .o_rid     (mem.r_id    ),
      .o_rdata   (mem.r_data  ),
      .o_rresp   (mem.r_resp  ),
      .o_rlast   (mem.r_last  ),
      .o_rvalid  (mem.r_valid ),
      .i_rready  (mem.r_ready ));

   wire        dmi_reg_en;
   wire [6:0]  dmi_reg_addr;
   wire        dmi_reg_wr_en;
   wire [31:0] dmi_reg_wdata;
   wire [31:0] dmi_reg_rdata;
   wire        dmi_hard_reset;

   wire        flash_sclk;

   STARTUPE2 STARTUPE2
     (
      .CFGCLK    (),
      .CFGMCLK   (),
      .EOS       (),
      .PREQ      (),
      .CLK       (1'b0),
      .GSR       (1'b0),
      .GTS       (1'b0),
      .KEYCLEARB (1'b1),
      .PACK      (1'b0),
      .USRCCLKO  (flash_sclk),
      .USRCCLKTS (1'b0),
      .USRDONEO  (1'b1),
      .USRDONETS (1'b0));

   bscan_tap tap
     (.clk            (clk_core),
      .rst            (rst_core),
      .jtag_id        (31'd0),
      .dmi_reg_wdata  (dmi_reg_wdata),
      .dmi_reg_addr   (dmi_reg_addr),
      .dmi_reg_wr_en  (dmi_reg_wr_en),
      .dmi_reg_en     (dmi_reg_en),
      .dmi_reg_rdata  (dmi_reg_rdata),
      .dmi_hard_reset (dmi_hard_reset),
      .rd_status      (2'd0),
      .idle           (3'd0),
      .dmi_stat       (2'd0),
      .version        (4'd1));

   swervolf_core
     #(.bootrom_file (bootrom_file))
   swervolf
     (.clk  (clk_core),
      .rstn (~rst_core),
      .dmi_reg_rdata  (dmi_reg_rdata),
      .dmi_reg_wdata  (dmi_reg_wdata),
      .dmi_reg_addr   (dmi_reg_addr ),
      .dmi_reg_en     (dmi_reg_en   ),
      .dmi_reg_wr_en  (dmi_reg_wr_en),
      .dmi_hard_reset (dmi_hard_reset),
      .o_flash_sclk   (flash_sclk),
      .o_flash_cs_n   (o_flash_cs_n),
      .o_flash_mosi   (o_flash_mosi),
      .i_flash_miso   (i_flash_miso),
      .i_uart_rx      (i_uart_rx),
      .o_uart_tx      (cpu_tx),
      .o_ram_awid     (cpu.aw_id),
      .o_ram_awaddr   (cpu.aw_addr),
      .o_ram_awlen    (cpu.aw_len),
      .o_ram_awsize   (cpu.aw_size),
      .o_ram_awburst  (cpu.aw_burst),
      .o_ram_awlock   (cpu.aw_lock),
      .o_ram_awcache  (cpu.aw_cache),
      .o_ram_awprot   (cpu.aw_prot),
      .o_ram_awregion (cpu.aw_region),
      .o_ram_awqos    (cpu.aw_qos),
      .o_ram_awvalid  (cpu.aw_valid),
      .i_ram_awready  (cpu.aw_ready),
      .o_ram_arid     (cpu.ar_id),
      .o_ram_araddr   (cpu.ar_addr),
      .o_ram_arlen    (cpu.ar_len),
      .o_ram_arsize   (cpu.ar_size),
      .o_ram_arburst  (cpu.ar_burst),
      .o_ram_arlock   (cpu.ar_lock),
      .o_ram_arcache  (cpu.ar_cache),
      .o_ram_arprot   (cpu.ar_prot),
      .o_ram_arregion (cpu.ar_region),
      .o_ram_arqos    (cpu.ar_qos),
      .o_ram_arvalid  (cpu.ar_valid),
      .i_ram_arready  (cpu.ar_ready),
      .o_ram_wdata    (cpu.w_data),
      .o_ram_wstrb    (cpu.w_strb),
      .o_ram_wlast    (cpu.w_last),
      .o_ram_wvalid   (cpu.w_valid),
      .i_ram_wready   (cpu.w_ready),
      .i_ram_bid      (cpu.b_id),
      .i_ram_bresp    (cpu.b_resp),
      .i_ram_bvalid   (cpu.b_valid),
      .o_ram_bready   (cpu.b_ready),
      .i_ram_rid      (cpu.r_id),
      .i_ram_rdata    (cpu.r_data),
      .i_ram_rresp    (cpu.r_resp),
      .i_ram_rlast    (cpu.r_last),
      .i_ram_rvalid   (cpu.r_valid),
      .o_ram_rready   (cpu.r_ready),
      .i_ram_init_done  (litedram_init_done),
      .i_ram_init_error (litedram_init_error),
      .i_gpio           ({32'd0,sw_2r,16'd0}),
      .o_gpio           (gpio_out),
      //NIBA
      .branches_counter (branches_counter),
      .branches_taken_counter (branches_taken_counter)
      //NIBA
     );

   always @(posedge clk_core) begin
      o_led <= led_int_r;
      led_int_r <= gpio_out[15:0];
      sw_r <= i_sw;
      sw_2r <= sw_r;
   end

   assign o_uart_tx = sw_2r[0] ? litedram_tx : cpu_tx;

endmodule
