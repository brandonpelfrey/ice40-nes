module mod_controller(
  input in_clk_controller,
  input in_vsync,
  input in_controller_data,
  output out_controller_latch,
  output out_controller_pulse,
  output[7:0] out_controller_buttons
);

reg [3:0] controller_state = 4'b0000;
reg [8:0] controller_shiftreg = 9'b0;

reg [7:0] controller_buttons = 8'b0000_0000;
reg controller_pulse = 1'b0;
reg controller_latch = 1'b0;

assign out_controller_pulse = controller_pulse;
assign out_controller_latch = controller_latch;
assign out_controller_buttons = controller_buttons;
//assign out_controller_buttons = controller_state;

always @(posedge in_clk_controller) begin
  if (!in_vsync) begin
    controller_pulse <= 1'b0;
    controller_latch <= 1'b0;
    controller_state <= 4'b1000;
    controller_shiftreg <= 9'b1_0000_0000;
  end else begin
    casex (controller_state)
      4'b0xxx: begin
        controller_pulse <= 1'b0;
        controller_latch <= 1'b0;
        controller_state <= 4'b0000;
        controller_buttons <= controller_shiftreg[8:1];
      end

      4'b1000: begin
        controller_pulse <= 1'b0;
        controller_latch <= 1'b1;
        controller_state <= 4'b1001;
      end

      4'b1001: begin
        controller_pulse <= 1'b0;
        controller_latch <= 1'b1;
        controller_state <= 4'b1010;
      end

      4'b1010: begin
        controller_pulse <= 1'b0;
        controller_latch <= 1'b0;
        controller_state <= 4'b1011;
      end

      4'b1011: begin
        controller_pulse <= 1'b0;
        controller_latch <= 1'b0;
        controller_shiftreg <= { in_controller_data, controller_shiftreg[8:1] };
        if (controller_shiftreg[1] == 1'b0) begin
          controller_state <= 4'b1100;
        end else begin
          controller_state <= 4'b0000;
        end
      end

      4'b1100: begin
        controller_pulse <= 1'b1;
        controller_latch <= 1'b0;
        controller_state <= 4'b1011;
      end
    endcase
  end
end

endmodule
