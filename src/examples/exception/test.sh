#!/bin/bash

$HOME/swig/swig -c++ -javascript -duk example.i &&
g++ -g -DSWIGRUNTIME_DEBUG -lduktape -shared example.cxx -o libexample.so &&
gcc -g -L. -lexample -lduktape harness.c -o harness