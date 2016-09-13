#!/bin/bash

rm harness
rm libexample.so
/Users/alex/swig/swig -javascript -duk example.i
gcc -g -DSWIGRUNTIME_DEBUG -lduktape -shared example_wrap.c -o libexample.so
gcc -g -L. -lexample -lduktape harness.c -o harness
