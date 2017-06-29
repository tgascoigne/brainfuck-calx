package bfuck;

// Calx runtime functions

extern "builtin" assert: fn(cond: bool, msg: string);
extern "builtin" len: fn(v: any) -> int;
extern "builtin" cap: fn(v: any) -> int;
