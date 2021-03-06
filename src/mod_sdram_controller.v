/*
    https://embeddedmicro.com/tutorials/mojo/sdram

    This SDRAM controller is for the Mojo's SDRAM shield which uses
    a 48LC32M8A2-7E SDRAM chip. This module was designed under the
    assumption that the click rate is 100MHz. Timing values would
    need to be re-evaluated under different clock rates.

    This controller features two basic improvements over the most
    basic of controllers. It does burst reads and writes of 4 bytes,
    and it only closes a row when it has to.

    Modified to work with an ice40 and IS42S81600F-6TLI sdram.
*/
module mod_sdram_controller (
    input in_sdram_clk,
    input in_rst,

    // these signals go directly to the IO pins
    output out_sdram_cle,
    output out_sdram_cs,
    output out_sdram_cas,
    output out_sdram_ras,
    output out_sdram_we,
    output out_sdram_dqm,
    output [1:0] out_sdram_ba,
    output [11:0] out_sdram_a,
    inout [7:0] inout_sdram_dq,

    // User interface
    input [21:0] in_addr,      // address to read/write
    input in_rw,               // 1 = write, 0 = read
    input [31:0] in_data,      // data from a read
    output [31:0] out_data,    // data for a write
    output out_busy,           // controller is busy when high
    input in_valid,            // pulse high to initiate a read/write
    output out_valid           // pulses high when data from read is valid
);

    // Commands for the SDRAM
    localparam CMD_UNSELECTED    = 4'b1000;
    localparam CMD_NOP           = 4'b0111;
    localparam CMD_ACTIVE        = 4'b0011;
    localparam CMD_READ          = 4'b0101;
    localparam CMD_WRITE         = 4'b0100;
    localparam CMD_TERMINATE     = 4'b0110;
    localparam CMD_PRECHARGE     = 4'b0010;
    localparam CMD_REFRESH       = 4'b0001;
    localparam CMD_LOAD_MODE_REG = 4'b0000;

    localparam STATE_SIZE = 4;
    localparam INIT = 0,
               WAIT = 1,
               PRECHARGE_INIT = 2,
               REFRESH_INIT_1 = 3,
               REFRESH_INIT_2 = 4,
               LOAD_MODE_REG = 5,
               IDLE = 6,
               REFRESH = 7,
               ACTIVATE = 8,
               READ = 9,
               READ_RES = 10,
               WRITE = 11,
               PRECHARGE = 12;

    // registers for SDRAM signals
    reg cle_d, dqm_d;
    reg [3:0] cmd_d;
    reg [1:0] ba_d;
    reg [11:0] a_d;
    reg [7:0] dq_d;
    reg [7:0] dqi_d;

    // We want the output/input registers to be embedded in the
    // IO buffers so we set IOB to "TRUE". This is to ensure all
    // the signals are sent and received at the same time.
    (* IOB = "TRUE" *)
    reg cle_q, dqm_q;
    (* IOB = "TRUE" *)
    reg [3:0] cmd_q;
    (* IOB = "TRUE" *)
    reg [1:0] ba_q;
    (* IOB = "TRUE" *)
    reg [12:0] a_q;
    (* IOB = "TRUE" *)
    reg [7:0] dq_q;
    (* IOB = "TRUE" *)
    wire [7:0] dqi_q;
    reg dq_en_d, dq_en_q;

    // Output assignments
    assign out_sdram_cle = cle_q;
    assign out_sdram_cs = cmd_q[3];
    assign out_sdram_ras = cmd_q[2];
    assign out_sdram_cas = cmd_q[1];
    assign out_sdram_we = cmd_q[0];
    assign out_sdram_dqm = dqm_q;
    assign out_sdram_ba = ba_q;
    assign out_sdram_a = a_q;

    // assign inout_sdram_dq = dq_en_q ? dq_q : 8'hZZ;

    SB_IO #(
      // The output pin may be tristated using the enable
      // Simple input pin
      .PIN_TYPE(6'b 1010_01),
      .PULLUP(1'b 0)
    ) data_io [7:0] (
      .PACKAGE_PIN(inout_sdram_dq),
      .OUTPUT_ENABLE(dq_en_d), // only drive when dq_en_q is 3
      .D_OUT_0(dq_q),
      .D_IN_0(dqi_q)
    );

    reg [STATE_SIZE-1:0] state_d, state_q = INIT;
    reg [STATE_SIZE-1:0] next_state_d, next_state_q;

    reg [21:0] addr_d, addr_q;
    reg [31:0] data_d, data_q;
    reg out_valid_d, out_valid_q;

    assign out_data = data_q;
    assign out_busy = !ready_q;
    assign out_valid = out_valid_q;

    reg [15:0] delay_ctr_d, delay_ctr_q;
    reg [1:0] byte_ctr_d, byte_ctr_q;

    reg [9:0] refresh_ctr_d, refresh_ctr_q;
    reg refresh_flag_d, refresh_flag_q;

    reg ready_d, ready_q;
    reg saved_rw_d, saved_rw_q;
    reg [21:0] saved_addr_d, saved_addr_q;
    reg [31:0] saved_data_d, saved_data_q;

    reg rw_op_d, rw_op_q;

    reg [3:0] row_open_d, row_open_q;
    reg [11:0] row_addr_d[3:0], row_addr_q[3:0];

    reg [2:0] precharge_bank_d, precharge_bank_q;
    integer i;

    always @* begin
        // Default values
        dq_d = dq_q;
        dqi_d = dqi_q;
        dq_en_d = 1'b0; // normally keep the bus in high-Z
        cle_d = cle_q;
        cmd_d = CMD_NOP; // default to NOP
        dqm_d = 1'b0;
        ba_d = 2'd0;
        a_d = 11'd0;
        state_d = state_q;
        next_state_d = next_state_q;
        delay_ctr_d = delay_ctr_q;
        addr_d = addr_q;
        data_d = data_q;
        out_valid_d = 1'b0;
        precharge_bank_d = precharge_bank_q;
        rw_op_d = rw_op_q;
        byte_ctr_d = 2'd0;

        row_open_d = row_open_q;

        // row_addr is a 2d array and must be copied this way
        for (i = 0; i < 4; i = i + 1)
            row_addr_d[i] = row_addr_q[i];

        // The data in the SDRAM must be refreshed periodically.
        // This counter ensures that the data remains intact.
        refresh_flag_d = refresh_flag_q;
        refresh_ctr_d = refresh_ctr_q + 1'b1;

        // This is probably much faster than needed
        if (refresh_ctr_q > 10'd750) begin
            refresh_ctr_d = 10'd0;
            refresh_flag_d = 1'b1;
        end

        saved_rw_d = saved_rw_q;
        saved_data_d = saved_data_q;
        saved_addr_d = saved_addr_q;
        ready_d = ready_q;

        // This is a queue of 1 for read/write operations.
        // When the queue is empty we aren't busy and can
        // accept another request.
        if (ready_q && in_valid) begin
            saved_rw_d = in_rw;
            saved_data_d = in_data;
            saved_addr_d = in_addr;
            ready_d = 1'b0;
        end

        case (state_q)
            ///// INITIALIZATION /////
            INIT: begin
                ready_d = 1'b0;
                row_open_d = 4'b0;
                out_valid_d = 1'b0;
                a_d = 11'b0;
                ba_d = 2'b0;
                cle_d = 1'b1;
                state_d = WAIT;
                delay_ctr_d = 16'd19000; // wait for 101us
                next_state_d = PRECHARGE_INIT;
                dq_en_d = 1'b0;
            end
            WAIT: begin
                delay_ctr_d = delay_ctr_q - 1'b1;
                if (delay_ctr_q == 13'd0) begin
                    state_d = next_state_q;
                    if (next_state_q == WRITE) begin
                        dq_en_d = 1'b1; // enable the bus early
                        dq_d = data_q[7:0];
                    end
                end
            end
            PRECHARGE_INIT: begin
                cmd_d = CMD_PRECHARGE;
                a_d[10] = 1'b1; // all banks
                ba_d = 2'd0;
                state_d = WAIT;
                next_state_d = REFRESH_INIT_1;
                delay_ctr_d = 13'd0;
            end
            REFRESH_INIT_1: begin
                cmd_d = CMD_REFRESH;
                state_d = WAIT;
                delay_ctr_d = 13'd7;
                next_state_d = REFRESH_INIT_2;
            end
            REFRESH_INIT_2: begin
                cmd_d = CMD_REFRESH;
                state_d = WAIT;
                delay_ctr_d = 13'd7;
                next_state_d = LOAD_MODE_REG;
            end
            LOAD_MODE_REG: begin
                cmd_d = CMD_LOAD_MODE_REG;
                ba_d = 2'b0;
                a_d = { 2'b00,   // Reserved
                         1'b0,   // Burst Access
                        2'b00,   // Standard Op Mode
                       3'b010,   // CAS = 2
                         1'b0,   // Sequential
                       3'b010 }; // Burst = 4
                state_d = WAIT;
                delay_ctr_d = 13'd2;
                next_state_d = IDLE;
                refresh_flag_d = 1'b0;
                refresh_ctr_d = 10'b1;
                ready_d = 1'b1;
            end

            ///// IDLE STATE /////
            IDLE: begin
                if (refresh_flag_q) begin // we need to do a refresh
                    state_d = PRECHARGE;
                    next_state_d = REFRESH;
                    precharge_bank_d = 3'b100; // all banks
                    refresh_flag_d = 1'b0; // clear the refresh flag
                end else if (!ready_q) begin // operation waiting
                    ready_d = 1'b1; // clear the queue
                    rw_op_d = saved_rw_q; // save the values we'll need later
                    addr_d = saved_addr_q;

                    if (saved_rw_q) // Write
                        data_d = saved_data_q;

                    // if the row is open we don't have to activate it
                    if (row_open_q[saved_addr_q[21:20]]) begin
                        if (row_addr_q[saved_addr_q[21:20]] == saved_addr_q[19:8]) begin
                            // Row is already open
                            if (saved_rw_q)
                                state_d = WRITE;
                            else
                                state_d = READ;
                        end else begin
                            // A different row in the bank is open
                            state_d = PRECHARGE; // precharge open row
                            precharge_bank_d = {1'b0, saved_addr_q[21:20]};
                            next_state_d = ACTIVATE; // open current row
                        end
                    end else begin
                        // no rows open
                        state_d = ACTIVATE; // open the row
                    end
                end
            end

            ///// REFRESH /////
            REFRESH: begin
                cmd_d = CMD_REFRESH;
                state_d = WAIT;
                delay_ctr_d = 13'd6; // gotta wait 7 clocks
                next_state_d = IDLE;
            end

            ///// ACTIVATE /////
            ACTIVATE: begin
                cmd_d = CMD_ACTIVE;
                a_d = addr_q[19:8];
                ba_d = addr_q[21:20];
                delay_ctr_d = 13'd0;
                state_d = WAIT;

                if (rw_op_q)
                    next_state_d = WRITE;
                else
                    next_state_d = READ;

                row_open_d[addr_q[21:20]] = 1'b1; // row is now open
                row_addr_d[addr_q[21:20]] = addr_q[19:8];
            end

            ///// READ /////
            READ: begin
                cmd_d = CMD_READ;
                a_d = {2'b0, addr_q[7:0], 2'b0};
                ba_d = addr_q[21:20];
                state_d = WAIT;
                delay_ctr_d = 13'd2; // wait for the data to show up
                next_state_d = READ_RES;

            end
            READ_RES: begin
                byte_ctr_d = byte_ctr_q + 1'b1; // we need to read in 4 bytes
                data_d = {dqi_q, data_q[31:8]}; // shift the data in
                if (byte_ctr_q == 2'd3) begin
                    out_valid_d = 1'b1;
                    state_d = IDLE;
                end
            end

            ///// WRITE /////
            WRITE: begin
                byte_ctr_d = byte_ctr_q + 1'b1; // send out 4 bytes

                if (byte_ctr_q == 2'd0) // first byte send write command
                    cmd_d = CMD_WRITE;

                dq_d = data_q[7:0];
                data_d = {8'h00, data_q[31:8]}; // shift the data out
                dq_en_d = 1'b1; // enable out bus
                a_d = {2'b0, addr_q[7:0], 2'b00};
                ba_d = addr_q[21:20];

                if (byte_ctr_q == 2'd3) begin
                    state_d = IDLE;
                end
            end

            ///// PRECHARGE /////
            PRECHARGE: begin
                cmd_d = CMD_PRECHARGE;
                a_d[10] = precharge_bank_q[2]; // all banks
                ba_d = precharge_bank_q[1:0];
                state_d = WAIT;
                delay_ctr_d = 13'd0;

                if (precharge_bank_q[2]) begin
                    row_open_d = 4'b0000; // closed all rows
                end else begin
                    row_open_d[precharge_bank_q[1:0]] = 1'b0; // closed one row
                end
            end

            default: state_d = INIT;
        endcase

    end

    always @(posedge in_sdram_clk) begin
        if(in_rst) begin
            cle_q <= 1'b0;
            dq_en_q <= 1'b0;
            state_q <= INIT;
            ready_q <= 1'b0;
        end else begin
            cle_q <= cle_d;
            dq_en_q <= dq_en_d;
            state_q <= state_d;
            ready_q <= ready_d;
        end

        saved_rw_q <= saved_rw_d;
        saved_data_q <= saved_data_d;
        saved_addr_q <= saved_addr_d;

        cmd_q <= cmd_d;
        dqm_q <= dqm_d;
        ba_q <= ba_d;
        a_q <= a_d;
        dq_q <= dq_d;

        next_state_q <= next_state_d;
        refresh_flag_q <= refresh_flag_d;
        refresh_ctr_q <= refresh_ctr_d;
        data_q <= data_d;
        addr_q <= addr_d;
        out_valid_q <= out_valid_d;
        row_open_q <= row_open_d;
        for (i = 0; i < 4; i = i + 1)
            row_addr_q[i] <= row_addr_d[i];
        precharge_bank_q <= precharge_bank_d;
        rw_op_q <= rw_op_d;
        byte_ctr_q <= byte_ctr_d;
        delay_ctr_q <= delay_ctr_d;
    end
endmodule

