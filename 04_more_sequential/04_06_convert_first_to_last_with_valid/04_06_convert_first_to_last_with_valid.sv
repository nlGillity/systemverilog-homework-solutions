module conv_first_to_last_no_ready
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    output               down_last,
    output [width - 1:0] down_data
);
    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // See README for full description of the task with timing diagram.

    // logic package_started;

    // always_ff @(posedge clock)
    //     if (reset) package_started <= 1'b0;
    //     else       package_started <= up_valid & up_first;

    logic package_started;
    
    always_ff @(posedge clock)
             if (reset)    package_started <= 1'b0;
        else if (up_first) package_started <= 1'b1;

    logic [width - 1:0] data;
    
    always_ff @(posedge clock)
             if (reset)    data <= '0;
        else if (up_valid) data <= up_data;   

    assign down_valid = package_started & up_valid;
    assign down_data  = data;

    assign down_last = up_valid ? up_first : 'b0;

endmodule


// // --- support: upstream_traffic_generator.sv ---
// module upstream_traffic_generator
// # (
//     parameter width     = 8,
//               use_valid = 1
// )
// (
//     input                clock,
//     input                reset,

//     input                up_enable,

//     output               up_valid,
//     input                up_ready,
//     output               up_first,
//     output               up_last,
//     output [width - 1:0] up_data
// );

//     logic               valid;
//     logic               first;
//     logic               last;
//     logic [width - 1:0] data;

//     assign up_valid = valid;
//     wire   ready    = up_ready;
//     assign up_first = valid ? first : 'x;
//     assign up_last  = valid ? last  : 'x;
//     assign up_data  = valid ? data  : 'x;

//     always @ (posedge clock)
//     begin
//         if (reset)
//         begin
//             valid <= ~ use_valid;
//             first <= 1'b1;
//             last  <= 1'b1;
//             data  <= "A";
//         end
//         else
//         begin
//             if (use_valid & (~ valid | ready))
//                 valid <= up_enable & $urandom_range (0, 99) < 60;

//             if (valid & ready)
//             begin
//                 first <= last;
//                 last  <= $urandom_range (0, 99) < 30;
//                 data  <= $urandom_range ("A", "Z");
//             end
//         end
//     end

// endmodule



