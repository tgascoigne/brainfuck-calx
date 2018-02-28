package llvm

// Just enough of the llvm c api to do what we need

type Module uintptr
type Value uintptr
type Type uintptr
type Block uintptr
type Builder uintptr
type Context uintptr

type Op int
IntEQ: Op : 32

// Modules
extern "C" LLVMModuleCreateWithName: fn(name: string) -> Module
extern "C" LLVMDumpModule: fn(mod: Module)
extern "C" LLVMGetModuleContext: fn(module: Module) -> Context

// Globals
extern "C" LLVMAddFunction: fn(mod: Module, name: string, typ: Type) -> Value
extern "C" LLVMAddGlobal: fn(module: Module, t: Type, name: string) -> Value
extern "C" LLVMSetInitializer: fn(global: Value, val: Value)

// Types
extern "C" LLVMVoidType: fn() -> Type
extern "C" LLVMInt8Type: fn() -> Type
extern "C" LLVMInt32Type: fn() -> Type
extern "C" LLVMArrayType: fn(elem_type: Type, elem_count: uint32) -> Type
extern "C" LLVMFunctionType: fn(ret: Type, args: Type, argc: int, variadic: bool) -> Type
extern "C" LLVMStructCreateNamed: fn(ctx: Context, name: string) -> Type

// Constants
extern "C" LLVMConstInt: fn(typ: Type, n: uint64, sign_extend: bool) -> Value
extern "C" LLVMConstNull: fn(typ: Type) -> Value

// Blocks
extern "C" LLVMMoveBasicBlockBefore: fn(block: Block, pos: Block)
extern "C" LLVMMoveBasicBlockAfter: fn(block: Block, pos: Block)
extern "C" LLVMAppendBasicBlock: fn(f: Value, name: string) -> Block
extern "C" LLVMPositionBuilderAtEnd: fn(b: Builder, block: Block)

// Builder
extern "C" LLVMCreateBuilder: fn() -> Builder
extern "C" LLVMBuildAdd: fn(b: Builder, lhs: Value, rhs: Value, name: string) -> Value
extern "C" LLVMBuildSub: fn(b: Builder, lhs: Value, rhs: Value, name: string) -> Value
extern "C" LLVMBuildLoad: fn(b: Builder, ptr: Value, name: string) -> Value
extern "C" LLVMBuildStore: fn(b: Builder, val: Value, ptr: Value) -> Value
extern "C" LLVMBuildExtractElement: fn(b: Builder, val: Value, idx: Value, name: string) -> Value
extern "C" LLVMBuildCall: fn(b: Builder, fun: Value, args: Value, argc: int, name: string) -> Value
extern "C" LLVMBuildGEP: fn(b: Builder, ptr: Value, indices: Value, indc: int, name: string) -> Value
extern "C" LLVMBuildRet: fn(b: Builder, v: Value) -> Value
extern "C" LLVMBuildBr: fn(b: Builder, dest: Block) -> Value
extern "C" LLVMBuildCondBr: fn(b: Builder, cond: Value, then: Block, els: Block) -> Value
extern "C" LLVMBuildICmp: fn(b: Builder, op: Op, lhs: Value, rhs: Value, name: string) -> Value
