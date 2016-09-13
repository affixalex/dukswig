# Duktape SWIG binding design

## Building



## Assumptions About The Duktape Context

This currently assumes a shared `libduktape.so` in your `LD_LIBRARY_PATH`. I've 
only tested on MacOS and Linux but there shouldn't be any real issues with 
portability to other systems and this approach is very convenient for 
both development and debugging (e.g., you can upgrade components in isolation).

## Notes on Nomenclature

In SWIG parlance, a namespace refers to the parent object that is actually 
returned when you do `var example = require("example");`. For example, a SWIG 
module named `example` will export a single namespace named `example` which may 
contain many classes, functions, and constants. This can be slightly confusing, 
but it begins to make sense in a Stockholm Syndrome sort of way once you think 
about it a bit in the context of bindings for many different languages.

## The Lifetime Of A SWIG Module

The humble life of a Duktape SWIG module named `example` begins with a call to
`dukopen_example(duk_context *ctx)` which then calls 
`SWIG_InitializeModule(void *clientdata)`, which actually takes a
`duk_context *ctx` as an argument.

`SWIG_InitializeModule()` then calls `SWIG_GetModule(clientdata)` to see if the 
module has already been loaded and if it hasn't, it calls `SWIG_SetModule()` to 
initialize the `swig_module` and store a reference to it in the Duktape 
context. `SWIG_GetModule()` and `SWIG_SetModule()` are actually implemented 
within the Duktape binding itself, while `SWIG_InitializeModule` is essentially opaque and provided by SWIG.

### The Lifetime Of A SWIG Object Instance

In each object instance, property `\FFprivate` constains a pointer to a 
`swig_duk_userdata` structure.

SETTER: duk_idx_t $jswrapper(duk_context *ctx, char *propertyName)
GETTER: duk_idx_t $jswrapper(duk_context *ctx)

## On Naming Schemes And Installation

Since there isn't really a standard naming scheme for Duktape, I've chosen to 
expand upon the same entry point naming scheme I use for mininode. So a module 
named  `example.so` will have an entry point named `dukopen_example`. The use 
of mininode is totally optional, but doing this allows me to just focus on just 
one set of module loader conventions and get a lot of versatility.
