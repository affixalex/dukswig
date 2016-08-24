UNAME_S := $(shell uname -s)

DUK_CFLAGS = -DDUK_OPT_VERBOSE_ERRORS \
	-DDUK_OPT_PARANOID_ERRORS \
	-DDUK_OPT_AUGMENT_ERRORS \
	-DDUK_OPT_NO_BROWSER_LIKE \
	-DDUK_OPT_NO_BUFFEROBJECT_SUPPORT \
	-DDUK_OPT_NO_COMMONJS_MODULES \
	-DDUK_OPT_JSON_STRINGIFY_FASTPATH \
	-DDUK_OPT_INTERRUPT_COUNTER \
	-DDUK_OPT_FASTINT \

libduktape.so.1.5.0:
ifeq ($(UNAME_S),Linux)
	gcc $(DUK_CFLAGS) -shared -fPIC -std=c99 src/duktape.c -o libduktape.so.1.5.0
else ifeq ($(UNAME_S),Darwin)
	clang $(DUK_CFLAGS) -dynamiclib -std=c99 src/duktape.c \
	-current_version 5.0 -compatibility_version 5.0 -fvisibility=hidden \
	-o libduktape.1.dylib
endif

all: libduktape

clean:
ifeq ($(UNAME_S),Linux)
	rm -f libduktape.so.1.5.0
else ifeq ($(UNAME_S),Darwin)
	rm -f libduktape.1.dylib
endif
	
install: libduktape.so.1.5.0
ifeq ($(UNAME_S),Linux)
	sudo cp libduktape.so.1.5.0 /usr/lib
else ifeq ($(UNAME_S),Darwin)
	sudo cp libduktape.1.dylib /usr/lib
endif
	sudo cp src/duktape.h /usr/include
	sudo cp src/duk_config.h /usr/include
	
uninstall:
ifeq ($(UNAME_S),Linux)
	sudo rm -f /usr/lib/libduktape.so.1.5.0
else ifeq ($(UNAME_S),Darwin)
	sudo rm -f /usr/lib/libduktape.1.dylib
endif
	sudo rm -f /usr/include/duktape.h
	sudo rm -f /usr/include/duk_config.h