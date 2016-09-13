#!/bin/bash

/Users/alex/swig/swig -c++ -javascript -duk example.i
gcc -g -DSWIGRUNTIME_DEBUG -lduktape -shared example_wrap.c -o libexample.so
gcc -g -L. -lexample -lduktape harness.c -o harness