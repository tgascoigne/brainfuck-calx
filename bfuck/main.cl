package main

import parse
import irgen
import llvm
import c.io

main :: fn(argv: []string) -> int {
	source := argv[1]

	io.printf("Compiling %s\n", source)

	// Parse
	prog := parse.parse(source)

	// Compile
	module := irgen.build(source, prog)

	// Dump the generated llir
	llvm.LLVMDumpModule(module)
	return 0
}
