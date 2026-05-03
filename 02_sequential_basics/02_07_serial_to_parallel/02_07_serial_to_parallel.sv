//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      serial_valid,
    input                      serial_data,

    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);
    // Task:
    // Implement a module that converts single-bit serial data to the multi-bit parallel value.
    //
    // The module should accept one-bit values with valid interface in a serial manner.
    // After accumulating 'width' bits and receiving last 'serial_valid' input,
    // the module should assert the 'parallel_valid' at the same clock cycle
    // and output 'parallel_data' value.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.

    // Solution:
    logic [width - 1:0] buffer; // buffer   = {data[width - 2:0], preready};
                                // data     = parallel_data[width - 2:0];
                                // preready - бит, указывающий на то, что данные
                                // почти готовы, то есть не хватает последнего бита
                                // для выдачи parallel_data.

    // После сигнала rst 1 устанавливается в старший бит buffer (остальные - 0).
    // По ходу работы модуля эта единица будет сдвигаться в сторону младших битов
    // входящими данными (serial_data).
    always_ff @(posedge clk)
        if      (rst           ) buffer <= 1'b1 << $left(buffer); 
        else if (parallel_valid) buffer <= 1'b1 << $left(buffer);
        else if (serial_valid  ) buffer <= { serial_data, buffer[$left(buffer) : 1] };

    assign {parallel_data, parallel_valid} = (buffer[0] & serial_valid) 
                                           ? {serial_data, buffer} : {1'b0, '0};

endmodule
