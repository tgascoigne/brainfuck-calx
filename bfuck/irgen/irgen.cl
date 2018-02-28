package irgen

import stack
import bf
import llvm

// The amount of memory to give to the brainfuck program
BF_MEM_SIZE: uint32 : 30000

// The IR Generator state
type Irgen struct {
	builder: llvm.Builder,
	func: llvm.Value,

	// The stack of loops
	loops: <Loop>stack.Stack,

	// State globals
	mem: llvm.Value,
	ptr: llvm.Value,

	// Extern functions
	putchar: llvm.Value,
	getchar: llvm.Value,
}

// A set of blocks relating to a loop construct
type Loop struct {
	cond: llvm.Block,
	body: llvm.Block,
	join: llvm.Block,
}

build :: fn(name: string, prog: bf.Prog) -> llvm.Module {
	code := prog as []bf.Opcode
	module := llvm.LLVMModuleCreateWithName(name)
	builder := llvm.LLVMCreateBuilder()
	zero := llvm.LLVMConstInt(llvm.LLVMInt32Type(), 0u64, false)

	gen := &Irgen{
		builder: builder,
	}

	// The brainfuck program lives inside of a single 'main' function
	ctx := llvm.LLVMGetModuleContext(module)

	args := [[0]]llvm.Type{}
	main_fn_type := llvm.LLVMFunctionType(llvm.LLVMInt32Type(), [[0]]llvm.Type{} as llvm.Type, 0, false)
	main_fn := llvm.LLVMAddFunction(module, "main", main_fn_type)
	gen.func = main_fn

	// Create the 'memory' globals
	mem_type := llvm.LLVMArrayType(llvm.LLVMInt8Type(), BF_MEM_SIZE)
	mem_global := llvm.LLVMAddGlobal(module, mem_type, "memory")
	llvm.LLVMSetInitializer(mem_global, llvm.LLVMConstNull(mem_type))

	mem_ptr_type := llvm.LLVMInt32Type()
	mem_ptr_global := llvm.LLVMAddGlobal(module, mem_ptr_type, "ptr")
	llvm.LLVMSetInitializer(mem_ptr_global, zero)

	gen.mem = mem_global
	gen.ptr = mem_ptr_global

	// Create the external function declarations
	putchar_args := [[1]]llvm.Type{llvm.LLVMInt8Type()}
	putchar_fn_type := llvm.LLVMFunctionType(llvm.LLVMVoidType(), &putchar_args as llvm.Type, 1, false)
	gen.putchar = llvm.LLVMAddFunction(module, "putchar", putchar_fn_type)

	getchar_args := [[0]]llvm.Type{}
	getchar_fn_type := llvm.LLVMFunctionType(llvm.LLVMInt8Type(), &getchar_args as llvm.Type, 0, false)
	gen.getchar = llvm.LLVMAddFunction(module, "getchar", getchar_fn_type)

	// Create the entry block
	entry := llvm.LLVMAppendBasicBlock(gen.func, "entry")
	llvm.LLVMPositionBuilderAtEnd(builder, entry)

	// Compile it
	for i := 0; i < len(code); i++ {
		irgen_op(gen, code[i])
	}

	llvm.LLVMBuildRet(gen.builder, zero)
	return module
}

// Constructs a set of blocks for a new loop
irgen_create_loop :: fn(gen: *Irgen) -> Loop {
	return Loop{
		cond: llvm.LLVMAppendBasicBlock(gen.func, "loop_cond"),
		body: llvm.LLVMAppendBasicBlock(gen.func, "loop_body"),
		join: llvm.LLVMAppendBasicBlock(gen.func, "loop_join")
	}
}

// Generates the IR for a single opcode
irgen_op :: fn(gen: *Irgen, op: bf.Opcode) {
	zero := llvm.LLVMConstInt(llvm.LLVMInt32Type(), 0u64, false)
	zerou8 := llvm.LLVMConstInt(llvm.LLVMInt8Type(), 0u64, false)
	one := llvm.LLVMConstInt(llvm.LLVMInt32Type(), 1u64, false)
	oneu8 := llvm.LLVMConstInt(llvm.LLVMInt8Type(), 1u64, false)

	get_vptr := fn() -> llvm.Value {
		p := llvm.LLVMBuildLoad(gen.builder, gen.ptr, "")
		indices := [[2]]llvm.Value{zero, p}
		vp := llvm.LLVMBuildGEP(gen.builder, gen.mem, &indices as llvm.Value, 2, "")
		return vp
	}

	switch op {
	case bf.op_eof:
		// nop

	case bf.op_incp:
		// increment ptr by 1
		p := llvm.LLVMBuildLoad(gen.builder, gen.ptr, "")
		p = llvm.LLVMBuildAdd(gen.builder, p, one, "")
		llvm.LLVMBuildStore(gen.builder, p, gen.ptr)

	case bf.op_decp:
		// decrement ptr by 1
		p := llvm.LLVMBuildLoad(gen.builder, gen.ptr, "")
		p = llvm.LLVMBuildSub(gen.builder, p, one, "")
		llvm.LLVMBuildStore(gen.builder, p, gen.ptr)

	case bf.op_incd:
		// increment *ptr by 1
		vp := get_vptr()
		v := llvm.LLVMBuildLoad(gen.builder, vp, "")
		v = llvm.LLVMBuildAdd(gen.builder, v, oneu8, "")
		llvm.LLVMBuildStore(gen.builder, v, vp)

	case bf.op_decd:
		// decrement *ptr by 1
		vp := get_vptr()
		v := llvm.LLVMBuildLoad(gen.builder, vp, "")
		v = llvm.LLVMBuildSub(gen.builder, v, oneu8, "")
		llvm.LLVMBuildStore(gen.builder, v, vp)

	case bf.op_get:
		// write *ptr to stdout
		vp := get_vptr()
		v := llvm.LLVMBuildLoad(gen.builder, vp, "")

		args := [[1]]llvm.Value{v}
		llvm.LLVMBuildCall(gen.builder, gen.putchar, &args as llvm.Value, 1, "")

	case bf.op_put:
		// read character from stdin, write to *ptr
		args := [[0]]llvm.Value{}
		c := llvm.LLVMBuildCall(gen.builder, gen.getchar, &args as llvm.Value, 0, "")

		vp := get_vptr()
		llvm.LLVMBuildStore(gen.builder, c, vp)

	case bf.op_loop:
		// while (*ptr) {

		// create the loop blocks and push them onto our stack
		loop := irgen_create_loop(gen)
		stack.push<Loop>(&gen.loops, loop)

		// End the current block and go straight to the condition
		llvm.LLVMBuildBr(gen.builder, loop.cond)
		llvm.LLVMPositionBuilderAtEnd(gen.builder, loop.cond)

		// Compare *ptr to 0, and branch to either the loop body, or to ']'
		vp := get_vptr()
		v := llvm.LLVMBuildLoad(gen.builder, vp, "")
		cond := llvm.LLVMBuildICmp(gen.builder, llvm.IntEQ, v, zerou8, "")
		llvm.LLVMBuildCondBr(gen.builder, cond, loop.join, loop.body)

		// Carry on compiling the loop body
		llvm.LLVMPositionBuilderAtEnd(gen.builder, loop.body)

	case bf.op_join:
		// }

		// pop the current loop blocks from the stack
		loop := stack.pop<Loop>(&gen.loops)

		// End the current loop body by branching back to cond
		llvm.LLVMBuildBr(gen.builder, loop.cond)
		llvm.LLVMPositionBuilderAtEnd(gen.builder, loop.join)

	default:
		// probably a newline or something
	}
}
