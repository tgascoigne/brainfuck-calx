CALX=clcc
LLI=lli-mp-3.9
LDFLAGS=`llvm-config-mp-3.9 --libs --system-libs --cflags --ldflags core analysis executionengine interpreter native`
RUNTIME=../runtime

bfuck: irgen.cl parse.cl stdio.cl runtime.cl llvm.cl opcodes.cl stack.cl main.cl
	$(CALX) -runtime $(RUNTIME) -Xclang "$(LDFLAGS)" -o $@ $^
	chmod +x $@

%.ll: examples/%.bf bfuck
	./bfuck $< 2> $@

hello: hello.ll
	$(LLI) $<

mandelbrot: mandelbrot.ll
	$(LLI) $<

clean:
	-rm -rf bfuck hello.ll
.PHONY: clean
