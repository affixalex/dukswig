#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <limits.h>
#include <dlfcn.h>
#include <duktape.h>

extern int swig_duk_init(duk_context *ctx);

int main(int argc, char *argv[]) {
	duk_context *ctx = duk_create_heap_default();
	dlopen("libexample.so", RTLD_NOW);
	swig_duk_init(ctx);
	duk_peval_file(ctx, "example.js");
}