`define WORD_LEN 8
`define XTAL_CLK 100_000_000
`define BAUD 2400
`define CW $clog2(`XTAL_CLK / (`BAUD*16*2))   
`define CLK_DIV (`XTAL_CLK / (`BAUD*16*2))
