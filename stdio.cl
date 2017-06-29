package bfuck;

// C runtime functions

type file_t *void;
type whence_t int;
type size_t uint64;

EOF := -1;

SEEK_SET: whence_t = 0;
SEEK_CUR: whence_t = 1;
SEEK_END: whence_t = 2;

extern "C" fopen: fn(path: string, mode: string) -> file_t;
extern "C" fseek: fn(fd: file_t, offset: uint64, whence: whence_t) -> bool;
extern "C" ftell: fn(fd: file_t) -> size_t;
extern "C" fgetc: fn(fd: file_t) -> int;

extern "C" getch: fn() -> uint8;

extern "C" printf: fn(fmt: string, args: ...*void);

fsize := fn(file: file_t) -> size_t {
	pos := ftell(file);
	fseek(file, uint64(0), SEEK_END);
	size := ftell(file);
	fseek(file, pos, SEEK_SET);
	return size;
};
