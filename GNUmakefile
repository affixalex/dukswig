UNAME_S := $(shell uname -s)

#-DDUK_OPT_NO_BROWSER_LIKE
DUK_CFLAGS = -DDUK_OPT_VERBOSE_ERRORS \
	-DDUK_OPT_PARANOID_ERRORS \
	-DDUK_OPT_AUGMENT_ERRORS \
	-DDUK_OPT_NO_BUFFEROBJECT_SUPPORT \
	-DDUK_OPT_JSON_STRINGIFY_FASTPATH \
	-DDUK_OPT_INTERRUPT_COUNTER \
	-DDUK_OPT_FASTINT \
	-DDUK_OPT_DEBUG

libduktape:
ifeq ($(UNAME_S),Linux)
	gcc $(DUK_CFLAGS) -shared -fPIC -std=c99 src/duktape.c -o libduktape.so
else ifeq ($(UNAME_S),Darwin)
	clang -g3 $(DUK_CFLAGS) -dynamiclib src/duktape.c -fvisibility=hidden \
	-o libduktape.dylib
endif

all: libduktape

clean:
ifeq ($(UNAME_S),Linux)
	rm -f libduktape.so
else ifeq ($(UNAME_S),Darwin)
	rm -f libduktape.dylib
endif
	
install: libduktape
ifeq ($(UNAME_S),Linux)
	sudo cp libduktape.so /usr/local/lib
else ifeq ($(UNAME_S),Darwin)
	sudo cp libduktape.dylib /usr/local/lib
endif
	sudo cp src/duktape.h /usr/local/include
	sudo cp src/duk_config.h /usr/local/include
	
uninstall:
ifeq ($(UNAME_S),Linux)
	sudo rm -f /usr/local/lib/libduktape.so
else ifeq ($(UNAME_S),Darwin)
	sudo rm -f /usr/local/lib/libduktape.dylib
endif
	sudo rm -f /usr/local/include/duktape.h
	sudo rm -f /usr/local/include/duk_config.h