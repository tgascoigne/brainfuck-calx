package bfuck;

// The amount of memory to give to the brainfuck program
BF_MEM_SIZE := 30000;

// The IR Generator state
type Irgen struct {
	builder: LLBuilder,
	func: LLValue,

	// The stack of loops
	loops: Stack,

	// State globals
	mem: LLValue,
	ptr: LLValue,

	// Extern functions
	putchar: LLValue,
	getchar: LLValue
};

// A set of blocks relating to a loop construct
type Loop struct {
	cond: LLBlock,
	body: LLBlock,
	join: LLBlock,
};

irgen_prog := fn(name: string, prog: []Opcode) -> LLModule {
	module := LLVMModuleCreateWithName(name);
	builder := LLVMCreateBuilder();
	zero := LLVMConstInt(LLVMInt32Type(), 0u64, false);

	gen := &Irgen{
		builder: builder,
	};

	// The brainfuck program lives inside of a single 'main' function
	ctx := LLVMGetModuleContext(module);

	args := [0]LLType{};
	main_fn_type := LLVMFunctionType(LLVMInt32Type(), (LLType)(&args), 0, false);
	main_fn := LLVMAddFunction(module, "main", main_fn_type);
	gen.func = main_fn;

	// Create the 'memory' globals
	mem_type := LLVMArrayType(LLVMInt8Type(), uint32(BF_MEM_SIZE));
	mem_global := LLVMAddGlobal(module, mem_type, "memory");
	LLVMSetInitializer(mem_global, LLVMConstNull(mem_type));

	mem_ptr_type := LLVMInt32Type();
	mem_ptr_global := LLVMAddGlobal(module, mem_ptr_type, "ptr");
	LLVMSetInitializer(mem_ptr_global, zero);

	gen.mem = mem_global;
	gen.ptr = mem_ptr_global;

	// Create the external function declarations
	putchar_args := [1]LLType{LLVMInt8Type()};
	putchar_fn_type := LLVMFunctionType(LLVMVoidType(), (LLType)(&putchar_args), 1, false);
	gen.putchar = LLVMAddFunction(module, "putchar", putchar_fn_type);

	getchar_args := [0]LLType{};
	getchar_fn_type := LLVMFunctionType(LLVMInt8Type(), (LLType)(&getchar_args), 0, false);
	gen.getchar = LLVMAddFunction(module, "getchar", getchar_fn_type);

	// Create the entry block
	entry := LLVMAppendBasicBlock(gen.func, "entry");
	LLVMPositionBuilderAtEnd(builder, entry);

	// Compile it
	for i := 0; i < len(prog); i++ {
		irgen_op(gen, prog[i]);
	};

	LLVMBuildRet(gen.builder, zero);
	return module;
};

// Constructs a set of blocks for a new loop
irgen_create_loop := fn(gen: *Irgen) -> Loop {
	return Loop{
		cond: LLVMAppendBasicBlock(gen.func, "loop_cond"),
		body: LLVMAppendBasicBlock(gen.func, "loop_body"),
		join: LLVMAppendBasicBlock(gen.func, "loop_join")
	};
};

// Generates the IR for a single opcode
irgen_op := fn(gen: *Irgen, op: Opcode) {
	zero := LLVMConstInt(LLVMInt32Type(), 0u64, false);
	zerou8 := LLVMConstInt(LLVMInt8Type(), 0u64, false);
	one := LLVMConstInt(LLVMInt32Type(), 1u64, false);
	oneu8 := LLVMConstInt(LLVMInt8Type(), 1u64, false);

	get_vptr := fn() -> LLValue {
		p := LLVMBuildLoad(gen.builder, gen.ptr, "");
		indices := [2]LLValue{zero, p};
		vp := LLVMBuildGEP(gen.builder, gen.mem, (LLValue)(&indices), 2, "");
		return vp;
	};

	switch op {
	case op_eof:
		// nop

	case op_incp:
		// increment ptr by 1
		p := LLVMBuildLoad(gen.builder, gen.ptr, "");
		p = LLVMBuildAdd(gen.builder, p, one, "");
		LLVMBuildStore(gen.builder, p, gen.ptr);

	case op_decp:
		// decrement ptr by 1
		p := LLVMBuildLoad(gen.builder, gen.ptr, "");
		p = LLVMBuildSub(gen.builder, p, one, "");
		LLVMBuildStore(gen.builder, p, gen.ptr);

	case op_incd:
		// increment *ptr by 1
		vp := get_vptr();
		v := LLVMBuildLoad(gen.builder, vp, "");
		v = LLVMBuildAdd(gen.builder, v, oneu8, "");
		LLVMBuildStore(gen.builder, v, vp);

	case op_decd:
		// decrement *ptr by 1
		vp := get_vptr();
		v := LLVMBuildLoad(gen.builder, vp, "");
		v = LLVMBuildSub(gen.builder, v, oneu8, "");
		LLVMBuildStore(gen.builder, v, vp);

	case op_get:
		// write *ptr to stdout
		vp := get_vptr();
		v := LLVMBuildLoad(gen.builder, vp, "");

		args := [1]LLValue{v};
		LLVMBuildCall(gen.builder, gen.putchar, (LLValue)(&args), 1, "");

	case op_put:
		// read character from stdin, write to *ptr
		args := [0]LLValue{};
		c := LLVMBuildCall(gen.builder, gen.getchar, (LLValue)(&args), 0, "");

		vp := get_vptr();
		LLVMBuildStore(gen.builder, c, vp);

	case op_loop:
		// while (*ptr) {

		// create the loop blocks and push them onto our stack
		loop := irgen_create_loop(gen);
		stack_push(&gen.loops, loop);

		// End the current block and go straight to the condition
		LLVMBuildBr(gen.builder, loop.cond);
		LLVMPositionBuilderAtEnd(gen.builder, loop.cond);

		// Compare *ptr to 0, and branch to either the loop body, or to ']'
		vp := get_vptr();
		v := LLVMBuildLoad(gen.builder, vp, "");
		cond := LLVMBuildICmp(gen.builder, LLVMIntEQ, v, zerou8, "");
		LLVMBuildCondBr(gen.builder, cond, loop.join, loop.body);

		// Carry on compiling the loop body
		LLVMPositionBuilderAtEnd(gen.builder, loop.body);

	case op_join:
		// }

		// pop the current loop blocks from the stack
		loop := Loop(stack_pop(&gen.loops));

		// End the current loop body by branching back to cond
		LLVMBuildBr(gen.builder, loop.cond);
		LLVMPositionBuilderAtEnd(gen.builder, loop.join);

	default:
		// probably a newline or something
	};
};
