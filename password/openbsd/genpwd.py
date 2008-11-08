#!/usr/bin/env python 
import sys
# you nee to install the bcrypt python library to use that script
# debian, ubuntu: sudo apt-get install python-bcrypt
import bcrypt

if len(sys.argv) != 2:
    print sys.argv[0]+" password"
    sys.exit(1)

# Hash a password for the first time
print bcrypt.hashpw(sys.argv[1], bcrypt.gensalt())
