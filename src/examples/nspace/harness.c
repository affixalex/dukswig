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

void
mn_dump_error(duk_context *ctx, duk_idx_t idx) {
	if (duk_is_error(ctx, idx)) {
		duk_get_prop_string(ctx, -1, "stack");
		fprintf(stderr, "\n%s\n\n", duk_get_string(ctx, -1));
		duk_pop(ctx);
	} else {
		fprintf(
			stderr,
			"\nError: %s\n\n",
			duk_json_encode(ctx, idx)
		);
	}
}

int main(int argc, char *argv[]) {
	duk_context *ctx = duk_create_heap_default();
	dlopen("libexample.so", RTLD_NOW);
	swig_duk_init(ctx);
	if (duk_peval_file(ctx, "example.js") == 0) {
		printf("SUCCESS!\n");
		 printf("result is: %s\n", duk_safe_to_string(ctx, -1));
		return 0;
	} else {
		 printf("result is: %s\n", duk_safe_to_string(ctx, -1));
		mn_dump_error(ctx, -1);
		return 1;
	};
}