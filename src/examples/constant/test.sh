#!/bin/bash

$HOME/swig -javascript -duk example.i
g++ -g -DSWIGRUNTIME_DEBUG -lduktape -shared example_wrap.c -o libexample.so
gcc -g -L. -lexample -lduktape harness.c -o harness