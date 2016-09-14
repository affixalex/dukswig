#!/bin/bash

$HOME/swig/swig -c++ -javascript -duk example.i
gcc -g -DSWIGRUNTIME_DEBUG -lduktape -shared -lc++ example.cxx example_wrap.cxx -o libexample.so
gcc -g -L. -lexample -lduktape harness.c -o harness