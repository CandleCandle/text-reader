

Text-Reader
===========

Read a byte stream line-by-line

Intended as a replacement for the stdlib's `buffered.Reader.line()` where the input is always separated by `\r\n`.


Use
===

see the examples directory.


Developing
==========

API Objectives
--------------

1. Reasonably usable, minimal surprises
2. check-then-read, i.e. call `has\_line()` before `line()`

Implementation Objectives
-------------------------

1. No partial functions on the primary code-paths
2. Avoid memcopy and read iterations over the whole of the input

