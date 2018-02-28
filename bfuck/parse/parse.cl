package parse

import bf
import c.io

// Parse a brainfuck program into a slice of opcodes
parse :: fn(path: string) -> bf.Prog {
	file := io.fopen(path, "r")
	size := io.fsize(file)

	code := [size]bf.Opcode{}

	for i := 0 as io.size_t; i < size; i++ {
		c := io.fgetc(file)
		code[i] = c as bf.Opcode
	}

	return code as bf.Prog
}
