module orb_gaussian #(
   parameter DATA_WIDTH = 8,
   parameter IMG_WIDTH  = 512,
   parameter IMG_HEIGHT = 512
)(
   input  wire                   clk,
   input  wire                   rst,
   input  wire [DATA_WIDTH-1:0]  pixel_in,
   input  wire                   pixel_in_valid,
   output reg  [DATA_WIDTH-1:0]  pixel_out,
   output reg                    pixel_out_valid
);

   localparam X_COUNT_BIT = $clog2(IMG_WIDTH);
   localparam Y_COUNT_BIT = $clog2(IMG_HEIGHT);

   // line buffer provides 3 taps per row
   wire [DATA_WIDTH-1:0] dout_tap0, dout_tap1, dout_tap2;
   wire                  dout_valid;

   reg  [DATA_WIDTH-1:0] pixel_in_r;
   reg                   pixel_in_valid_r;
   reg  [DATA_WIDTH-1:0] window_pixels [1:3][1:3];
   reg  [X_COUNT_BIT-1:0] x_count;
   reg  [Y_COUNT_BIT-1:0] y_count;
   reg                   skip1;
   reg                   window_pixels_valid;

   line_buffer2 #(
      .DATA_WIDTH (DATA_WIDTH),
      .LINE_WORDS (IMG_WIDTH)
   ) u_line_buffer (
      .clk               (clk),
      .rst               (rst),
      .en                (pixel_in_valid_r),
      .din               (pixel_in_r),
      .dout_tap0         (dout_tap0),
      .dout_tap1         (dout_tap1),
      .dout_tap2         (dout_tap2),
      .dout_padded_valid (dout_valid)
   );

   integer x,y;
   always @(posedge clk or posedge rst) begin
      if (rst) begin
         pixel_in_r           <= {DATA_WIDTH{1'b0}};
         pixel_in_valid_r     <= 1'b0;
         skip1                <= 1'b0;
         window_pixels_valid  <= 1'b0;
         x_count              <= {X_COUNT_BIT{1'b0}};
         y_count              <= {Y_COUNT_BIT{1'b0}};
         for (y=1; y<=3; y=y+1) for (x=1; x<=3; x=x+1)
            window_pixels[x][y] <= {DATA_WIDTH{1'b0}};
      end else begin
         // register inputs
         pixel_in_r       <= pixel_in;
         pixel_in_valid_r <= pixel_in_valid;
         skip1            <= dout_valid ? 1'b1 : skip1;
         window_pixels_valid <= dout_valid && skip1;

         // counters
         x_count <= (window_pixels_valid && x_count==IMG_WIDTH-1) ? {X_COUNT_BIT{1'b0}} :
                    (window_pixels_valid) ? x_count + 1'b1 : x_count;
         y_count <= (window_pixels_valid && x_count==IMG_WIDTH-1 && y_count==IMG_HEIGHT-1) ? {Y_COUNT_BIT{1'b0}} :
                    (window_pixels_valid && x_count==IMG_WIDTH-1) ? y_count + 1'b1 : y_count;

         // shift window on valid tap
         if (dout_valid) begin
            window_pixels[3][1] <= dout_tap0;
            window_pixels[3][2] <= dout_tap1;
            window_pixels[3][3] <= dout_tap2;

            window_pixels[2][1] <= window_pixels[3][1];
            window_pixels[2][2] <= window_pixels[3][2];
            window_pixels[2][3] <= window_pixels[3][3];

            window_pixels[1][1] <= window_pixels[2][1];
            window_pixels[1][2] <= window_pixels[2][2];
            window_pixels[1][3] <= window_pixels[2][3];
         end
      end
   end

   // compute separable 3x3 Gaussian (weights 1 2 1;2 4 2;1 2 1) sum >> 4
   reg [DATA_WIDTH+3:0] gauss_sum; // enough width for accumulation
   wire padding = (x_count=={X_COUNT_BIT{1'b0}}) || (y_count=={Y_COUNT_BIT{1'b0}}) || (x_count==IMG_WIDTH-1) || (y_count==IMG_HEIGHT-1);

   always @(posedge clk or posedge rst) begin
      if (rst) begin
         gauss_sum <= '0;
         pixel_out <= {DATA_WIDTH{1'b0}};
         pixel_out_valid <= 1'b0;
      end else begin
         gauss_sum <=  (window_pixels[1][1] + (window_pixels[1][2] << 1) + window_pixels[1][3])
                     + ( (window_pixels[2][1] << 1) + (window_pixels[2][2] << 2) + (window_pixels[2][3] << 1) )
                     + (window_pixels[3][1] + (window_pixels[3][2] << 1) + window_pixels[3][3]);
         pixel_out <= padding ? {DATA_WIDTH{1'b0}} : (gauss_sum >> 4);
         pixel_out_valid <= window_pixels_valid;
      end
   end

endmodule