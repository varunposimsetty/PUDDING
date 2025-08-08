module dac_word_correction #(
  parameter RAW_WIDTH  = 8,
  parameter SEGMENTS   = 8,
  parameter FRACT_BITS = 8
) (
  input  wire                   clk_i,
  input  wire                   rst_ni,
  input  wire                   enable,   // 1=calibrate, 0=bypass
  input  wire [RAW_WIDTH-1:0]   raw_code,
  output reg  [RAW_WIDTH-1:0]   out_code
);
 
  // Derived constants
  localparam MAX_CD = (1<<RAW_WIDTH) - 1;
  localparam SEG_W  = (MAX_CD + 1) / SEGMENTS;
 
  // Internal signals
  reg signed [31:0] a0;
  reg signed [31:0] a1;
  reg signed [31:0] line_v;
  integer D;
  integer seg;
  integer result_i;
 
  // Combinational segment lookup
  always @(*) begin
    D   = raw_code;
    seg = D / SEG_W;
    if (seg >= SEGMENTS) seg = SEGMENTS - 1;
 
    // choose offset (A0_Counts) and slope (A1_Q8_8)
    case (seg)
      0: begin a0 = 0;   a1 = 256; end
      1: begin a0 = 1;   a1 = 250; end
      2: begin a0 = -1;  a1 = 256; end
      3: begin a0 = 2;   a1 = 262; end
      4: begin a0 = -2;  a1 = 248; end
      5: begin a0 = 0;   a1 = 264; end
      6: begin a0 = 0;   a1 = 256; end
      7: begin a0 = 0;   a1 = 256; end
      default: begin a0 = 0; a1 = 256; end
    endcase
  end
 
  // Sequential logic for bypass or calibration
  always @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      out_code <= 0;
    end else begin
      if (!enable) begin
        // bypass raw code
        out_code <= raw_code;
      end else begin
        // affine: offset + (slope * D) >> FRACT_BITS
        line_v = a0 + ((a1 * D) >>> FRACT_BITS);
        result_i = line_v;
        // clamp to [0, MAX_CD]
        if (result_i < 0)
          result_i = 0;
        else if (result_i > MAX_CD)
          result_i = MAX_CD;
        out_code <= result_i;
      end
    end
  end
 
endmodule
 