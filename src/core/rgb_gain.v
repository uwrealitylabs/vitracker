module rgb_gain
#(
	parameter	P_DEPTH			= 10,
	parameter	PW				= P_DEPTH*4
)
(
	input               i_pclk,
	input               i_arstn,
	
	input 		        i_hs,
	input               i_vs,
	input				i_de,
	input				i_valid,
	input [PW-1:0]  	i_data,
    input [2:0]         blue_gain,
    input [2:0]         green_gain,
    input [2:0]         red_gain,
	
	output              o_hs,
	output				o_vs,
	output				o_de,
	output				o_valid,
	output [PW-1:0]  	o_data
);

reg		[PW-1:0] 		r_data_filtered_4P;
		
reg		[P_DEPTH:0] 	r_odd_line_byte_3_2P;
reg		[P_DEPTH:0] 	r_odd_line_byte_2_2P;
reg		[P_DEPTH:0] 	r_odd_line_byte_1_2P;
reg		[P_DEPTH:0] 	r_odd_line_byte_0_2P;

reg		[P_DEPTH-1:0] 	r_odd_line_pix_3_3P;
reg		[P_DEPTH-1:0] 	r_odd_line_pix_2_3P;
reg		[P_DEPTH-1:0] 	r_odd_line_pix_1_3P;
reg		[P_DEPTH-1:0] 	r_odd_line_pix_0_3P;

reg		[P_DEPTH:0] 	r_even_line_byte_3_2P;
reg		[P_DEPTH:0] 	r_even_line_byte_2_2P;
reg		[P_DEPTH:0] 	r_even_line_byte_1_2P;
reg		[P_DEPTH:0] 	r_even_line_byte_0_2P;

reg		[P_DEPTH-1:0] 	r_even_line_pix_3_3P;
reg		[P_DEPTH-1:0] 	r_even_line_pix_2_3P;
reg		[P_DEPTH-1:0] 	r_even_line_pix_1_3P;
reg		[P_DEPTH-1:0] 	r_even_line_pix_0_3P;
		
reg		[P_DEPTH-1:0] 	r_byte_3_div_1_1P;
reg		[P_DEPTH-1:0] 	r_byte_2_div_1_1P;
reg		[P_DEPTH-1:0] 	r_byte_1_div_1_1P;
reg		[P_DEPTH-1:0] 	r_byte_0_div_1_1P;

reg		[P_DEPTH:0] 	r_g_3_div_2_1P;
reg		[P_DEPTH:0] 	r_g_3_div_4_1P;
reg		[P_DEPTH:0] 	r_g_3_div_1_4_1P;
reg		[P_DEPTH:0] 	r_b_2_div_2_1P;
reg		[P_DEPTH:0] 	r_b_2_div_4_1P;
reg		[P_DEPTH:0] 	r_b_2_div_1_4_1P;
reg		[P_DEPTH:0] 	r_g_1_div_2_1P;
reg		[P_DEPTH:0] 	r_g_1_div_4_1P;
reg		[P_DEPTH:0] 	r_g_1_div_1_4_1P;
reg		[P_DEPTH:0] 	r_b_0_div_2_1P;
reg		[P_DEPTH:0] 	r_b_0_div_4_1P;
reg		[P_DEPTH:0] 	r_b_0_div_1_4_1P;
reg		[P_DEPTH:0] 	r_r_3_div_2_1P;
reg		[P_DEPTH:0]		r_r_3_div_4_1P;
reg		[P_DEPTH:0] 	r_r_3_div_1_4_1P;
reg		[P_DEPTH:0] 	r_g_2_div_2_1P;
reg		[P_DEPTH:0] 	r_g_2_div_4_1P;
reg		[P_DEPTH:0] 	r_g_2_div_1_4_1P;
reg		[P_DEPTH:0] 	r_r_1_div_2_1P;
reg		[P_DEPTH:0] 	r_r_1_div_4_1P;
reg		[P_DEPTH:0] 	r_r_1_div_1_4_1P;
reg		[P_DEPTH:0] 	r_g_0_div_2_1P;
reg		[P_DEPTH:0] 	r_g_0_div_4_1P;
reg		[P_DEPTH:0] 	r_g_0_div_1_4_1P;


	
reg		r_line_cnt;

reg		r_blue_gain_1P;
reg 	r_green_gain_1P;
reg 	r_red_gain_1P;

/* SYNC delay */
reg				r_hs_1P;
reg				r_de_1P;
reg				r_vs_1P;
reg				r_valid_1P;
reg				r_hs_2P;
reg				r_de_2P;
reg				r_vs_2P;
reg				r_valid_2P;
reg				r_hs_3P;
reg				r_de_3P;
reg				r_vs_3P;
reg				r_valid_3P;
reg				r_hs_4P;
reg				r_de_4P;
reg				r_vs_4P;
reg				r_valid_4P;

wire	[P_DEPTH-1:0] 	byte_3_div_1;
wire	[P_DEPTH-1:0] 	byte_3_div_2;
wire	[P_DEPTH-1:0] 	byte_3_div_4;
wire	[P_DEPTH-1:0] 	byte_2_div_1;
wire	[P_DEPTH-1:0] 	byte_2_div_2;
wire	[P_DEPTH-1:0] 	byte_2_div_4;
wire	[P_DEPTH-1:0] 	byte_1_div_1;
wire	[P_DEPTH-1:0] 	byte_1_div_2;
wire	[P_DEPTH-1:0] 	byte_1_div_4;
wire	[P_DEPTH-1:0] 	byte_0_div_1;
wire	[P_DEPTH-1:0] 	byte_0_div_2;
wire	[P_DEPTH-1:0] 	byte_0_div_4;

/* RGB gain filter */   
assign byte_3_div_1 = i_data[PW-1:P_DEPTH*3];
assign byte_3_div_2 = byte_3_div_1 >> 1;
assign byte_3_div_4 = byte_3_div_1 >> 2;
assign byte_2_div_1 = i_data[P_DEPTH*3-1:P_DEPTH*2];
assign byte_2_div_2 = byte_2_div_1 >> 1;
assign byte_2_div_4 = byte_2_div_1 >> 2;
assign byte_1_div_1 = i_data[P_DEPTH*2-1:P_DEPTH];
assign byte_1_div_2 = byte_1_div_1 >> 1;
assign byte_1_div_4 = byte_1_div_1 >> 2;
assign byte_0_div_1 = i_data[P_DEPTH-1:0];
assign byte_0_div_2 = byte_0_div_1 >> 1;
assign byte_0_div_4 = byte_0_div_1 >> 2;

always@(posedge i_pclk)
begin
	if (~i_arstn)
	begin
		r_hs_1P		<= 1'b0;
		r_de_1P		<= 1'b0;
		r_vs_1P		<= 1'b0;
		r_valid_1P	<= 1'b0;
		r_hs_2P		<= 1'b0;
		r_de_2P		<= 1'b0;
		r_vs_2P		<= 1'b0;
		r_valid_2P	<= 1'b0;
		r_hs_3P		<= 1'b0;
		r_de_3P		<= 1'b0;
		r_vs_3P		<= 1'b0;
		r_valid_3P	<= 1'b0;
		r_line_cnt	<= 1'b0;
		r_blue_gain_1P	<= 1'b0;
		r_green_gain_1P	<= 1'b0;
		r_red_gain_1P	<= 1'b0;
		
		r_data_filtered_4P	<= {PW{1'b0}};
		r_byte_3_div_1_1P	<= {P_DEPTH{1'b0}};
		r_byte_2_div_1_1P	<= {P_DEPTH{1'b0}};
		r_byte_1_div_1_1P	<= {P_DEPTH{1'b0}};
		r_byte_0_div_1_1P	<= {P_DEPTH{1'b0}};		
		r_odd_line_byte_3_2P	<= {P_DEPTH+1{1'b0}};
		r_odd_line_byte_2_2P	<= {P_DEPTH+1{1'b0}};
		r_odd_line_byte_1_2P	<= {P_DEPTH+1{1'b0}};
		r_odd_line_byte_0_2P	<= {P_DEPTH+1{1'b0}};
		r_odd_line_pix_3_3P	<= {P_DEPTH{1'b0}};
		r_odd_line_pix_2_3P	<= {P_DEPTH{1'b0}};
		r_odd_line_pix_1_3P	<= {P_DEPTH{1'b0}};
		r_odd_line_pix_0_3P	<= {P_DEPTH{1'b0}};
		r_even_line_byte_3_2P	<= {P_DEPTH+1{1'b0}};
		r_even_line_byte_2_2P	<= {P_DEPTH+1{1'b0}};
		r_even_line_byte_1_2P	<= {P_DEPTH+1{1'b0}};
		r_even_line_byte_0_2P	<= {P_DEPTH+1{1'b0}};
		r_even_line_pix_3_3P	<= {P_DEPTH{1'b0}};
		r_even_line_pix_2_3P	<= {P_DEPTH{1'b0}};
		r_even_line_pix_1_3P	<= {P_DEPTH{1'b0}};
		r_even_line_pix_0_3P	<= {P_DEPTH{1'b0}};
	end
	else
	begin
		r_de_1P		<= i_de;
		r_hs_1P		<= i_hs;
		r_vs_1P		<= i_vs;	
		r_valid_1P	<= i_valid;
		r_de_2P		<= r_de_1P;
		r_hs_2P		<= r_hs_1P;
		r_vs_2P		<= r_vs_1P;	
		r_valid_2P	<= r_valid_1P;
		r_de_3P		<= r_de_2P;
		r_hs_3P		<= r_hs_2P;
		r_vs_3P		<= r_vs_2P;	
		r_valid_3P	<= r_valid_2P;
		r_de_4P		<= r_de_3P;
		r_hs_4P		<= r_hs_3P;
		r_vs_4P		<= r_vs_3P;	
		r_valid_4P	<= r_valid_3P;
		
		r_blue_gain_1P	<= blue_gain[2];
		r_green_gain_1P	<= green_gain[2];
		r_red_gain_1P	<= red_gain[2];
		
		if (r_vs_3P && !r_vs_2P)
			r_line_cnt	<= 1'b0;
		if (r_de_3P && !r_de_2P)
			r_line_cnt 	<= ~r_line_cnt;
				
		r_byte_3_div_1_1P	<= byte_3_div_1;
		r_byte_2_div_1_1P	<= byte_2_div_1;
		r_byte_1_div_1_1P	<= byte_1_div_1;
		r_byte_0_div_1_1P	<= byte_0_div_1;
		
		// Gb B Gb B		
		if (green_gain[2])
		begin
			r_g_3_div_2_1P	<= (byte_3_div_2 & {P_DEPTH{green_gain[1]}});
			r_g_3_div_4_1P	<= (byte_3_div_4 & {P_DEPTH{green_gain[0]}});
		end
		else
		begin
			r_g_3_div_2_1P	<= (byte_3_div_2 & {P_DEPTH{~green_gain[1]}});
			r_g_3_div_4_1P	<= (byte_3_div_4 & {P_DEPTH{~green_gain[0]}});
			r_g_3_div_1_4_1P	<= byte_3_div_1 - byte_3_div_4;
		end		
		if (r_green_gain_1P)
			r_odd_line_byte_3_2P	<= r_byte_3_div_1_1P + r_g_3_div_2_1P + r_g_3_div_4_1P;
		else
			r_odd_line_byte_3_2P	<= r_g_3_div_1_4_1P - r_g_3_div_2_1P - r_g_3_div_4_1P;
			
		if (blue_gain[2])
		begin
			r_b_2_div_2_1P	<= (byte_2_div_2 & {P_DEPTH{blue_gain[1]}});
			r_b_2_div_4_1P	<= (byte_2_div_4 & {P_DEPTH{blue_gain[0]}});
		end
		else
		begin
			r_b_2_div_2_1P	<= (byte_2_div_2 & {P_DEPTH{~blue_gain[1]}});
			r_b_2_div_4_1P	<= (byte_2_div_4 & {P_DEPTH{~blue_gain[0]}});
			r_b_2_div_1_4_1P	<= byte_2_div_1 - byte_2_div_4;
		end
		if (r_blue_gain_1P)
			r_odd_line_byte_2_2P	<= r_byte_2_div_1_1P + r_b_2_div_2_1P + r_b_2_div_4_1P;
		else
			r_odd_line_byte_2_2P	<= r_b_2_div_1_4_1P - r_b_2_div_2_1P - r_b_2_div_4_1P;
		
		if (green_gain[2])
		begin
			r_g_1_div_2_1P	<= (byte_1_div_2 & {P_DEPTH{green_gain[1]}});
			r_g_1_div_4_1P	<= (byte_1_div_4 & {P_DEPTH{green_gain[0]}});
		end
		else
		begin
			r_g_1_div_2_1P	<= (byte_1_div_2 & {P_DEPTH{~green_gain[1]}});
			r_g_1_div_4_1P	<= (byte_1_div_4 & {P_DEPTH{~green_gain[0]}});
			r_g_1_div_1_4_1P	<= byte_1_div_1 - byte_1_div_4;
		end
		if (r_green_gain_1P)
			r_odd_line_byte_1_2P	<= r_byte_1_div_1_1P + r_g_1_div_2_1P + r_g_1_div_4_1P;
		else
			r_odd_line_byte_1_2P	<= r_g_1_div_1_4_1P - r_g_1_div_2_1P - r_g_1_div_4_1P;
		
		if (blue_gain[2])
		begin
			r_b_0_div_2_1P	<= (byte_0_div_2 & {P_DEPTH{blue_gain[1]}});
			r_b_0_div_4_1P	<= (byte_0_div_4 & {P_DEPTH{blue_gain[0]}});
		end
		else
		begin
			r_b_0_div_2_1P	<= (byte_0_div_2 & {P_DEPTH{~blue_gain[1]}});
			r_b_0_div_4_1P	<= (byte_0_div_4 & {P_DEPTH{~blue_gain[0]}});
			r_b_0_div_1_4_1P	<= byte_0_div_1 - byte_0_div_4;
		end
		if (r_blue_gain_1P)
			r_odd_line_byte_0_2P	<= r_byte_0_div_1_1P + r_b_0_div_2_1P + r_b_0_div_4_1P;
		else
			r_odd_line_byte_0_2P	<= r_b_0_div_1_4_1P - r_b_0_div_2_1P - r_b_0_div_4_1P;
		
		// R Gr R Gr
		if (red_gain[2])
		begin
			r_r_3_div_2_1P	<= (byte_3_div_2 & {P_DEPTH{red_gain[1]}});
			r_r_3_div_4_1P	<= (byte_3_div_4 & {P_DEPTH{red_gain[0]}});
		end
		else
		begin
			r_r_3_div_2_1P	<= (byte_3_div_2 & {P_DEPTH{~red_gain[1]}});
			r_r_3_div_4_1P	<= (byte_3_div_4 & {P_DEPTH{~red_gain[0]}});
			r_r_3_div_1_4_1P	<= byte_3_div_1-byte_3_div_4;
		end
		if (r_red_gain_1P)
			r_even_line_byte_3_2P	<= r_byte_3_div_1_1P + r_r_3_div_2_1P + r_r_3_div_4_1P;
		else
			r_even_line_byte_3_2P	<= r_r_3_div_1_4_1P - r_r_3_div_2_1P - r_r_3_div_4_1P;
				
		if (green_gain[2])
		begin
			r_g_2_div_2_1P	<= (byte_2_div_2 & {P_DEPTH{green_gain[1]}});
			r_g_2_div_4_1P	<= (byte_2_div_4 & {P_DEPTH{green_gain[0]}});
		end
		else
		begin
			r_g_2_div_2_1P	<= (byte_2_div_2 & {P_DEPTH{~green_gain[1]}});
			r_g_2_div_4_1P	<= (byte_2_div_4 & {P_DEPTH{~green_gain[0]}});
			r_g_2_div_1_4_1P	<= byte_2_div_1-byte_2_div_4;
		end
		if (r_green_gain_1P)
			r_even_line_byte_2_2P	<= r_byte_2_div_1_1P + r_g_2_div_2_1P + r_g_2_div_4_1P;
		else
			r_even_line_byte_2_2P	<= r_g_2_div_1_4_1P - r_g_2_div_2_1P - r_g_2_div_4_1P;
				
		if (red_gain[2])
		begin
			r_r_1_div_2_1P	<= (byte_1_div_2 & {P_DEPTH{red_gain[1]}});
			r_r_1_div_4_1P	<= (byte_1_div_4 & {P_DEPTH{red_gain[0]}});
		end
		else
		begin
			r_r_1_div_2_1P	<= (byte_1_div_2 & {P_DEPTH{~red_gain[1]}});
			r_r_1_div_4_1P	<= (byte_1_div_4 & {P_DEPTH{~red_gain[0]}});
			r_r_1_div_1_4_1P	<= byte_1_div_1-byte_1_div_4;
		end
		if (r_red_gain_1P)
			r_even_line_byte_1_2P	<=	r_byte_1_div_1_1P + r_r_1_div_2_1P + r_r_1_div_4_1P;
		else
			r_even_line_byte_1_2P	<=	r_r_1_div_1_4_1P - r_r_1_div_2_1P - r_r_1_div_4_1P;
		
		if (green_gain[2])
		begin
			r_g_0_div_2_1P	<= (byte_0_div_2 & {P_DEPTH{green_gain[1]}});
			r_g_0_div_4_1P	<= (byte_0_div_4 & {P_DEPTH{green_gain[0]}});
		end
		else
		begin
			r_g_0_div_2_1P	<= (byte_0_div_2 & {P_DEPTH{~green_gain[1]}});
			r_g_0_div_4_1P	<= (byte_0_div_4 & {P_DEPTH{~green_gain[0]}});
			r_g_0_div_1_4_1P	<= byte_0_div_1-byte_0_div_4;
		end
		if (r_green_gain_1P)
			r_even_line_byte_0_2P	<= r_byte_0_div_1_1P + r_g_0_div_2_1P + r_g_0_div_4_1P;
		else
			r_even_line_byte_0_2P	<= r_g_0_div_1_4_1P - r_g_0_div_2_1P - r_g_0_div_4_1P;
		
		//
		if (r_odd_line_byte_3_2P[P_DEPTH])
			r_odd_line_pix_3_3P	<= {P_DEPTH{1'b1}};
		else
			r_odd_line_pix_3_3P	<= r_odd_line_byte_3_2P[P_DEPTH-1:0];
			
		if (r_odd_line_byte_2_2P[P_DEPTH])
			r_odd_line_pix_2_3P	<= {P_DEPTH{1'b1}};
		else
			r_odd_line_pix_2_3P	<= r_odd_line_byte_2_2P[P_DEPTH-1:0];
	
		if (r_odd_line_byte_1_2P[P_DEPTH])
			r_odd_line_pix_1_3P	<= {P_DEPTH{1'b1}};
		else
			r_odd_line_pix_1_3P	<= r_odd_line_byte_1_2P[P_DEPTH-1:0];
	
		if (r_odd_line_byte_0_2P[P_DEPTH])
			r_odd_line_pix_0_3P	<= {P_DEPTH{1'b1}};
		else
			r_odd_line_pix_0_3P	<= r_odd_line_byte_0_2P[P_DEPTH-1:0];
	
		if (r_even_line_byte_3_2P[P_DEPTH])
			r_even_line_pix_3_3P	<= {P_DEPTH{1'b1}};
		else
			r_even_line_pix_3_3P	<= r_even_line_byte_3_2P[P_DEPTH-1:0];
			
		if (r_even_line_byte_2_2P[P_DEPTH])
			r_even_line_pix_2_3P	<= {P_DEPTH{1'b1}};
		else
			r_even_line_pix_2_3P	<= r_even_line_byte_2_2P[P_DEPTH-1:0];
	
		if (r_even_line_byte_1_2P[P_DEPTH])
			r_even_line_pix_1_3P	<= {P_DEPTH{1'b1}};
		else
			r_even_line_pix_1_3P	<= r_even_line_byte_1_2P[P_DEPTH-1:0];
	
		if (r_even_line_byte_0_2P[P_DEPTH])
			r_even_line_pix_0_3P	<= {P_DEPTH{1'b1}};
		else
			r_even_line_pix_0_3P	<= r_even_line_byte_0_2P[P_DEPTH-1:0];
	
		//
		if (r_line_cnt)
			r_data_filtered_4P	<= {r_even_line_pix_3_3P,r_even_line_pix_2_3P,r_even_line_pix_1_3P,r_even_line_pix_0_3P};
		else
			r_data_filtered_4P	<= {r_odd_line_pix_3_3P, r_odd_line_pix_2_3P, r_odd_line_pix_1_3P, r_odd_line_pix_0_3P};
	end
end

//assign	o_hs	= i_hs;
//assign	o_de	= i_de;
//assign	o_vs	= i_vs;
//assign	o_valid	= i_valid;
//assign	o_data	= w_data_filtered;

assign	o_hs	= r_hs_4P;
assign	o_de	= r_de_4P;
assign	o_vs	= r_vs_4P;
assign	o_valid	= r_valid_4P;
assign	o_data	= r_data_filtered_4P;

endmodule
