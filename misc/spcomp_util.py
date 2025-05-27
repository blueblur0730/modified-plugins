#!/usr/bin/python3

import subprocess
import io

def extract_version(spcomp):
	"""
	Extract version string from caption in SourcePawn compiler into a tuple.
	The string is hardcoded in `setcaption(void)` in `sourcepawn/compiler/parser.cpp`
	"""
	p = subprocess.Popen([spcomp], stdout=subprocess.PIPE)
	caption = io.TextIOWrapper(p.stdout, encoding="utf-8").readline()
	
	# extracts last element from output in format "SourcePawn Compiler major.minor.rev.patch"
	*_, version = caption.split()
	return tuple(map(int, version.split('.')))
