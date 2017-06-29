package bfuck;

// Just enough of the llvm c api to do what we need

type LLModule *void;
type LLValue *void;
type LLType *void;
type LLBlock *void;
type LLBuilder *void;
type LLContext *void;

type LLOp int;
LLVMIntEQ: LLOp = 32;

// Modules
extern "C" LLVMModuleCreateWithName: fn(name: string) -> LLModule;
extern "C" LLVMDumpModule: fn(mod: LLModule);
extern "C" LLVMGetModuleContext: fn(module: LLModule) -> LLContext;

// Globals
extern "C" LLVMAddFunction: fn(mod: LLModule, name: string, typ: LLType) -> LLValue;
extern "C" LLVMAddGlobal: fn(module: LLModule, t: LLType, name: string) -> LLValue;
extern "C" LLVMSetInitializer: fn(global: LLValue, val: LLValue);

// Types
extern "C" LLVMVoidType: fn() -> LLType;
extern "C" LLVMInt8Type: fn() -> LLType;
extern "C" LLVMInt32Type: fn() -> LLType;
extern "C" LLVMArrayType: fn(elem_type: LLType, elem_count: uint32) -> LLType;
extern "C" LLVMFunctionType: fn(ret: LLType, args: LLType, argc: int, variadic: bool) -> LLType;
extern "C" LLVMStructCreateNamed: fn(ctx: LLContext, name: string) -> LLType;

// Constants
extern "C" LLVMConstInt: fn(typ: LLType, n: uint64, sign_extend: bool) -> LLValue;
extern "C" LLVMConstNull: fn(typ: LLType) -> LLValue;

// Blocks
extern "C" LLVMMoveBasicBlockBefore: fn(block: LLBlock, pos: LLBlock);
extern "C" LLVMMoveBasicBlockAfter: fn(block: LLBlock, pos: LLBlock);
extern "C" LLVMAppendBasicBlock: fn(f: LLValue, name: string) -> LLBlock;
extern "C" LLVMPositionBuilderAtEnd: fn(b: LLBuilder, block: LLBlock);

// Builder
extern "C" LLVMCreateBuilder: fn() -> LLBuilder;
extern "C" LLVMBuildAdd: fn(b: LLBuilder, lhs: LLValue, rhs: LLValue, name: string) -> LLValue;
extern "C" LLVMBuildSub: fn(b: LLBuilder, lhs: LLValue, rhs: LLValue, name: string) -> LLValue;
extern "C" LLVMBuildLoad: fn(b: LLBuilder, ptr: LLValue, name: string) -> LLValue;
extern "C" LLVMBuildStore: fn(b: LLBuilder, val: LLValue, ptr: LLValue) -> LLValue;
extern "C" LLVMBuildExtractElement: fn(b: LLBuilder, val: LLValue, idx: LLValue, name: string) -> LLValue;
extern "C" LLVMBuildCall: fn(b: LLBuilder, fun: LLValue, args: LLValue, argc: int, name: string) -> LLValue;
extern "C" LLVMBuildGEP: fn(b: LLBuilder, ptr: LLValue, indices: LLValue, indc: int, name: string) -> LLValue;
extern "C" LLVMBuildRet: fn(b: LLBuilder, v: LLValue) -> LLValue;
extern "C" LLVMBuildBr: fn(b: LLBuilder, dest: LLBlock) -> LLValue;
extern "C" LLVMBuildCondBr: fn(b: LLBuilder, cond: LLValue, then: LLBlock, els: LLBlock) -> LLValue;
extern "C" LLVMBuildICmp: fn(b: LLBuilder, op: LLOp, lhs: LLValue, rhs: LLValue, name: string) -> LLValue;
