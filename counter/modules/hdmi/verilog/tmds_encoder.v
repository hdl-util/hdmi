module tmds_encoder (
  input            clkin,    // pixel clock input
  input            rstin,    // async. reset input (active high)
  input      [7:0] din,      // data inputs: expect registered
  output reg [9:0] dout      // data outputs
);

wire [3:0] Nb1s = din[0] + din[1] + din[2] + din[3] + din[4] + din[5] + din[6] + din[7];
wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && din[0]==1'b0);
wire [8:0] q_m = {~XNOR, q_m[6:0] ^ din[7:1] ^ {7{XNOR}}, din[0]};

reg [3:0] balance_acc = 0;
wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
wire balance_sign_eq = (balance[3] == balance_acc[3]);
wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
wire [9:0] dout_w = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};

always @(posedge clkin) dout <= dout_w;
always @(posedge clkin or posedge rstin) balance_acc <= rstin ? 4'd0 : balance_acc_new;

endmodule
