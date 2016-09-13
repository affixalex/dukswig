example_wrap.c: example.i
	/Users/alex/swig/swig -duk example.i

EXAMPLE_OBJS += \
	example_wrap.o \
	duktape.o

$(EXAMPLE_OBJS): %.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm example_wrap.*
	rm $(EXAMPLE_OBJS)
	
example: $(EXAMPLE_OBJS)
	
all: example_wrap.c example
	$(CC) $(EXAMPLE_OBJS) -o example