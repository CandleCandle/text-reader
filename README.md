

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

# Reasonably usable, minimal surprises
# check-then-read, i.e. call `has\_line()` before `line()`

Implementation Objectives
-------------------------

# No partial functions on the primary code-paths
# Avoid memcopy and read iterations over the whole of the input

