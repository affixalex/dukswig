# Duktape with SWIG

I'm targeting the latest stable release of Duktape 1.x because the 2.x API is 
still in flux. While a real project will likely embed Duktape, this builds a 
shared library to keep the components totally separated. I think that in order 
to upstream Duktape support to mainline SWIG, it will be desirable to support 
both use cases. Debian Unstable currently packages a shared Duktape and other 
distributions are likely to follow, so this may become fairly common.

https://github.com/svaarala/duktape/pull/959
https://github.com/svaarala/duktape/issues/930

## Overall Plan

1. Update configure.ac to search for a Duktape installation
2. Update Makefile.in to build Lib/javascript/duk
3. Test-driven development against swig/Lib/javascript/duk/*

## Developing With Vagrant

I'm using Virtualbox and the Alpine Linux edge release in the base box, which 
includes GCC 6.1 and generally has very up-to-date packages. This approach 
could be used to produce a binary statically linked against musl-libc which 
would run on any Linux system. You make run into some clock skew warnings. 

Alpine Linux 3.5 should have first class support for VirtualBox guest additions.

In order to build on Alpine...

    vagrant up
    cd /dukswig
    make && make install

To uninstall and clean...

    make uninstall && make clean

I'll be adding some Duktape specific SWIG tests here.

## Thoughts on a JSCore Wrapper

I've been weighing this option, and I think that the maintenance burden and 
runtime overhead aren't really worth it given the scope here. Particularly 
given the impending transition to Duktape 2.x, I think it makes more sense to
focus on using SWIG and upstreaming the work. There are also a few impedance 
mismatches in the APIs that would make it less than ideal, in my opinion.