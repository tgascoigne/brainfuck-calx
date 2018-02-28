CALX=calxcc
LLI=lli
RUNTIME=../calx/runtime
STDLIB=../calx/std
LDFLAGS=`llvm-config --libs --system-libs --cflags --ldflags core analysis executionengine interpreter native`

BIN=bfuckcc
PKG_DIR=bfuck
SOURCES=$(wildcard $(PKG_DIR)/*.cl)

$(BIN): $(SOURCES)
	$(CALX) -I $(STDLIB) -runtime $(RUNTIME) -Xclang "$(LDFLAGS)" -o $@ $(PKG_DIR)
	chmod +x $@

%.ll: examples/%.bf $(BIN)
	./$(BIN) $< 2> $@

hello: hello.ll
	$(LLI) $<

mandelbrot: mandelbrot.ll
	$(LLI) $<

clean:
	-rm -rf bfuck hello.ll
.PHONY: clean
