# A repro case for a strange crash...

...involving plumbum, boost.python, gold and clang's `--rtlib=compiler-rt` option.

## Pre-requisites

Tested with:

* cmake version 3.20.3
* Conan version 1.36.0
* Python 3.8.5
* plumbum 1.7.0
* Ubuntu clang version 12.0.1-++20210630032618+fed41342a82f-1~exp1~20210630133332.127
* Ubuntu 20.04.2 LTS

## Build

Run `build.sh`.

## Reproduce

Run `main.py` with proper env:

```
$ LD_PRELOAD=$(clang++-12 -print-file-name=libclang_rt.asan-x86_64.so) ./main.py 
imported
AddressSanitizer:DEADLYSIGNAL
=================================================================
==486711==ERROR: AddressSanitizer: SEGV on unknown address 0x7f2616f92f0b (pc 0x7f261c314675 bp 0x7f2617d65800 sp 0x7f2617d64fb8 T1)
==486711==The signal is caused by a READ memory access.
```

## GDB

GDB can profile some additional info:

* Run `gdb --args python3 main.py`
* Enter command `set environment LD_PRELOAD=/usr/lib/llvm-12/lib/clang/12.0.1/lib/linux/libclang_rt.asan-x86_64.so`
* Run program

```
$ gdb --args python3 main.py
GNU gdb (Ubuntu 10.2-0ubuntu1~20.04~1) 10.2
Copyright (C) 2021 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from python3...
(No debugging symbols found in python3)
(gdb) set environment LD_PRELOAD=/usr/lib/llvm-12/lib/clang/12.0.1/lib/linux/libclang_rt.asan-x86_64.so
(gdb) r
Starting program: /usr/bin/python3 main.py
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
[New Thread 0x7ffff2f98700 (LWP 487421)]
[Detaching after fork from child process 487422]
imported

Thread 2 "python3" received signal SIGSEGV, Segmentation fault.
[Switching to Thread 0x7ffff2f98700 (LWP 487421)]
__strlen_avx2 () at ../sysdeps/x86_64/multiarch/strlen-avx2.S:65
65	../sysdeps/x86_64/multiarch/strlen-avx2.S: No such file or directory.
(gdb) bt
#0  __strlen_avx2 () at ../sysdeps/x86_64/multiarch/strlen-avx2.S:65
#1  0x00007ffff75f4909 in strlen () from /usr/lib/llvm-12/lib/clang/12.0.1/lib/linux/libclang_rt.asan-x86_64.so
#2  0x00007ffff6bfb295 in get_cie_encoding (cie=cie@entry=0x7ffff21aaf02) at ../../../libgcc/unwind-dw2-fde.c:300
#3  0x00007ffff6bfb44e in classify_object_over_fdes (ob=0x7ffff21e6408 <__do_init.__object>, this_fde=0x7ffff21bb000) at ../../../libgcc/unwind-dw2-fde.c:659
#4  0x00007ffff6bfc59c in init_object (ob=0x7ffff21e6408 <__do_init.__object>) at ../../../libgcc/unwind-dw2-fde.c:780
#5  search_object (ob=0x7ffff21e6408 <__do_init.__object>, pc=0x7ffff6bfaa85 <_Unwind_ForcedUnwind+53>) at ../../../libgcc/unwind-dw2-fde.c:992
#6  0x00007ffff6bfcf56 in _Unwind_Find_registered_FDE (bases=0x7ffff2f97c78, pc=0x7ffff6bfaa85 <_Unwind_ForcedUnwind+53>) at ../../../libgcc/unwind-dw2-fde.c:1069
#7  _Unwind_Find_FDE (pc=0x7ffff6bfaa85 <_Unwind_ForcedUnwind+53>, bases=bases@entry=0x7ffff2f97c78) at ../../../libgcc/unwind-dw2-fde-dip.c:458
#8  0x00007ffff6bf8fd8 in uw_frame_state_for (context=0x7ffff2f97bd0, fs=0x7ffff2f97a10) at ../../../libgcc/unwind-dw2.c:1263
#9  0x00007ffff6bfa1a0 in uw_init_context_1 (context=0x7ffff2f97bd0, outer_cfa=0x7ffff2f97e00, outer_ra=0x7ffff738ef06 <__GI___pthread_unwind+70>) at ../../../libgcc/unwind-dw2.c:1592
#10 0x00007ffff6bfaa86 in _Unwind_ForcedUnwind (exc=0x7ffff2f98d70, stop=stop@entry=0x7ffff738ed70 <unwind_stop>, stop_argument=0x7ffff2f97e90) at ../../../libgcc/unwind.inc:211
#11 0x00007ffff738ef06 in __GI___pthread_unwind (buf=<optimized out>) at unwind.c:121
#12 0x00007ffff7385972 in __do_cancel () at pthreadP.h:310
#13 __pthread_exit (value=<optimized out>) at pthread_exit.c:28
#14 0x00007ffff743558a in __pthread_exit (retval=<optimized out>) at forward.c:141
#15 0x0000000000674f8b in PyThread_exit_thread ()
#16 0x0000000000654fed in ?? ()
#17 0x0000000000674ac8 in ?? ()
#18 0x00007ffff7384609 in start_thread (arg=<optimized out>) at pthread_create.c:477
#19 0x00007ffff74c0293 in clone () at ../sysdeps/unix/sysv/linux/x86_64/clone.S:95
(gdb) 
```

## Analysis

The crash happens at this line: https://github.com/tomerfiliba/plumbum/blob/master/plumbum/commands/processes.py#L286

The crash does NOT happen if you do any of the following:
* remove `-fuse-ld=gold` compiler option
* remove `import build.libextension` from `main.py`
* remove `--rtlib=compiler-rt` from `CMakeLists.txt` (you would alse need to remove `mul()` function from `extension.cpp` in this case)

If you remove sanitizers, the program crashes with Segmentation fault with a different callstack:
```
$ gdb --args python3 main.py 
...
Thread 1 "python3" received signal SIGABRT, Aborted.
__GI_raise (sig=sig@entry=6) at ../sysdeps/unix/sysv/linux/raise.c:50
50	../sysdeps/unix/sysv/linux/raise.c: No such file or directory.
(gdb) bt
#0  __GI_raise (sig=sig@entry=6) at ../sysdeps/unix/sysv/linux/raise.c:50
#1  0x00007ffff7ded859 in __GI_abort () at abort.c:79
#2  0x00007ffff5dfcd46 in __deregister_frame_info_bases (begin=0x7ffff63e0000) at ../../../libgcc/unwind-dw2-fde.c:244
#3  __deregister_frame_info_bases (begin=0x7ffff63e0000) at ../../../libgcc/unwind-dw2-fde.c:201
#4  0x00007ffff63e688f in __do_fini () from /home/mmatrosov/dev/temp/plumbum-crash-repro/build/libextension.so
#5  0x00007ffff7fe0f5b in _dl_fini () at dl-fini.c:138
#6  0x00007ffff7e11a27 in __run_exit_handlers (status=0, listp=0x7ffff7fb3718 <__exit_funcs>, run_list_atexit=run_list_atexit@entry=true, run_dtors=run_dtors@entry=true) at exit.c:108
#7  0x00007ffff7e11be0 in __GI_exit (status=<optimized out>) at exit.c:139
#8  0x00007ffff7def0ba in __libc_start_main (main=0x4eee60 <main>, argc=2, argv=0x7fffffffe358, init=<optimized out>, fini=<optimized out>, rtld_fini=<optimized out>, stack_end=0x7fffffffe348)
    at ../csu/libc-start.c:342
#9  0x00000000005f9ece in _start ()
```
