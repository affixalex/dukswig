#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <limits.h>
#include <duktape.h>

static void dump_object(duk_context *ctx, duk_idx_t idx) {
	idx = duk_require_normalize_index(ctx, idx);

	/* The weird fn() helper is to handle lightfunc name printing (= avoid it). */
	duk_eval_string(ctx,
	    "(function (o) {\n"
	    "    Object.getOwnPropertyNames(o).forEach(function (k) {\n"
	    "        var pd = Object.getOwnPropertyDescriptor(o, k);\n"
	    "        function fn(x) { if (x.name !== 'getter' && x.name !== 'setter') { return 'func' }; return x.name; }\n"
	    "        print(Duktape.enc('jx', k), Duktape.enc('jx', pd), (pd.get ? fn(pd.get) : 'no-getter'), (pd.set ? fn(pd.set) : 'no-setter'));\n"
	    "    });\n"
	    "})");
	duk_dup(ctx, idx);
	duk_call(ctx, 1);
	duk_pop(ctx);
}

static duk_ret_t _wrap_FCONST(duk_context *ctx)
{
  /* FRAGMENT: js_getter */
  duk_push_number(ctx, (duk_double_t) 2.1828);
  duk_idx_t jsresult = duk_get_top(ctx);
  return jsresult;
}

static duk_ret_t JS_veto_set_variable(duk_context *ctx)
{
  duk_push_string(ctx, "Tried to write a read-only variable.");
  duk_throw(ctx);
  return duk_get_top(ctx); /* We should never get here, but stifle warning. */
}

int main(int argc, char *argv[]) {
	duk_context *ctx = duk_create_heap_default();
	duk_push_global_object(ctx);
	duk_idx_t obj_idx = duk_push_object(ctx);
	duk_push_string(ctx, "FCONST");
	duk_push_c_function(ctx, _wrap_FCONST, 0 /* nargs */);
	duk_push_c_function(ctx, JS_veto_set_variable, 1 /* nargs */);
	duk_def_prop(ctx, obj_idx, DUK_DEFPROP_HAVE_GETTER|DUK_DEFPROP_HAVE_SETTER|DUK_DEFPROP_HAVE_CONFIGURABLE);
	duk_put_prop_string(ctx, -2, "example");
	dump_object(ctx, -1);
	duk_peval_file(ctx, "example.js");
}

//
//print("TESTING FROM JS!");
//print(typeof(example));
//print(FCONST);