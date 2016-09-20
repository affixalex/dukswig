#!/bin/bash

$HOME/swig/swig -c++ -javascript -duk example.i
g++ -g -lduktape -shared example_wrap.cxx -o libexample.so
gcc -g -L. -lexample -lduktape harness.c -o harness