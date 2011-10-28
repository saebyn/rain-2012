#!/usr/bin/env python
import glob
import os
import os.path

from build import convert


dirname = os.path.dirname(os.path.abspath(__file__))
os.chdir(dirname)

for fn in glob.glob('*.yaml'):
    try:
        with open(os.path.join('../../src/assets',
                               fn.replace('yaml', 'json')), 'w') as f:
            f.write(convert(fn))
    except:
        print 'Failed to convert %s.' % fn
