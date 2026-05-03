//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module parallel_to_serial
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      parallel_valid,
    input        [width - 1:0] parallel_data,

    output                     busy,
    output logic               serial_valid,
    output logic               serial_data
);
    // Task:
    // Implement a module that converts multi-bit parallel value to the single-bit serial data.
    //
    // The module should accept 'width' bit input parallel data when 'parallel_valid' input is asserted.
    // At the same clock cycle as 'parallel_valid' is asserted, the module should output
    // the least significant bit of the input data. In the following clock cycles the module
    // should output all the remaining bits of the parallel_data.
    // Together with providing correct 'serial_data' value, module should also assert the 'serial_valid' output.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.

    // Solution: 
    enum bit {
        IDLE, 
        BUSY
    } state, next_state;

    logic [width - 1]    data;
    logic [$clog2(width)] ptr;

    localparam last_ptr = width - 2;

    // Логика конечного автомата
    always_ff @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next_state;

    always_comb begin
        next_state = IDLE;
        case (state)
            IDLE: if (parallel_valid ) next_state = BUSY;
                else                   next_state = IDLE;
            BUSY: if (ptr == last_ptr) next_state = IDLE;  
                else                   next_state = BUSY;
        endcase
    end

    // Логика регистров
    always_ff @(posedge clk) begin : data_reg
             if (rst)            data <= '0;
        else if (parallel_valid) data <= parallel_data[width - 1:1];
        else if (busy)           data <= { 1'b0, data[$left(data):1] };
    end

    always_ff @(posedge clk) begin : ptr_reg
        if      (rst)            ptr <= '0;
        else if (parallel_valid) ptr <= '0;
        else if (busy)           ptr <= ptr + 1'b1;
    end

    // Комбинационная логика на выходе модуля
    assign busy         = state == BUSY,
           serial_valid = parallel_valid | busy,
           serial_data  = parallel_valid ? parallel_data[0] : data[0];
    

endmodule
