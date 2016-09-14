#!/bin/bash

export CFLAGS = -Wno-unknown-escape-sequence

for dir in src/examples/*/; do
	cd $dir && ./test.sh;
	cd ..
done