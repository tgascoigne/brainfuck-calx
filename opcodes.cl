package bfuck;

// The opcodes of a brainfuck program
type Opcode uint8;

// nop
op_eof := Opcode(0);

// increment ptr by 1
op_incp := Opcode('>');

// decrement ptr by 1
op_decp := Opcode('<');

// increment *ptr by 1
op_incd := Opcode('+');

// decrement *ptr by 1
op_decd := Opcode('-');

// write *ptr to stdout
op_get := Opcode('.');

// read character from stdin, write to *ptr
op_put := Opcode(',');

// while (*ptr) {
op_loop := Opcode('[');

// }
op_join := Opcode(']');
