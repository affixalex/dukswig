#!/bin/bash

$HOME/swig/swig -c++ -javascript -duk example.i
g++ -g -DSWIGRUNTIME_DEBUG -fPIC -lduktape -shared example.cxx example_wrap.cxx -o libexample.so
gcc -g -L. -lexample -lduktape harness.c -o harness