package bfuck;

// Parse a brainfuck program into a slice of opcodes
parse := fn(path: string) -> []Opcode {
	file := fopen(path, "r");
	size := fsize(file);

	code: [size]Opcode;

	for i := size_t(0); i < size; i++ {
		c := fgetc(file);
		code[i] = Opcode(c);
	};

	return code;
};
