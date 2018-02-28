package bf

// A brainfuck program
type Prog []Opcode

// The opcodes of a brainfuck program
type Opcode uint8

op_eof: Opcode: 0 // nop
op_incp: Opcode: '>' // increment ptr by 1
op_decp: Opcode: '<' // decrement ptr by 1
op_incd: Opcode: '+' // increment *ptr by 1
op_decd: Opcode: '-' // decrement *ptr by 1
op_get: Opcode: '.' // write *ptr to stdout
op_put: Opcode: ',' // read character from stdin, write to *ptr
op_loop: Opcode: '[' // while (*ptr) {
op_join: Opcode: ']' // }
