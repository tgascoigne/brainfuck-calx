package bfuck;

main := fn(argc: int, argv: *[2]string) -> int {
	// argv handling is a little hacky, need to rethink how to irgen unbounded arrays

	source := argv[1];

	printf("Compiling %s\n", source);

	// Parse
	prog := parse(argv[1]);

	// Compile
	module := irgen_prog(source, prog);

	// Dump the generated llir
	LLVMDumpModule(module);
	return 0;
};
