#!/bin/bash

$HOME/swig/swig -javascript -duk example.i
gcc -g -DSWIGRUNTIME_DEBUG -lduktape -shared example.c example_wrap.c -o libexample.so
gcc -g -L. -lexample -lduktape harness.c -o harness
