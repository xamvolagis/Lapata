import xml.etree.cElementTree as ET
import os
import csv
import gzip
import numpy as np
cimport numpy as np
DTYPE = np.int
ctypedef np.int_t DTYPE_t
import re
import string
pattern = re.compile('[\W_]+')


cdef main_(str inf, str outco, str outwv):
    f = gzip.open(inf, 'r')
    fc = open(outco, 'w')
    ow = open(outwv, 'w')
    oc = csv.writer(fc, delimiter='\t')
    cdef:
        int i = 1
        float cert, certt
        str word, simp, pos

    for event, elem in ET.iterparse(f):
        if elem.tag == 's':
            i = 1
            ow.write('\n')
        elif elem.tag == 't':
            word = elem.attrib['f']
            pos = '-'
            #base = '-'
            cert = 0
            for child in elem.getchildren():
                if child.tag == 'P':
                    certt = float(child.attrib.get('c', -1))
                    if certt > cert or certt == -1:
                        pos = child.attrib['t']
                        if certt != -1:
                            cert = certt
            oc.writerow([str(i), word, '-', '-', pos, '-',
                         '-', '-', '-', '-', '-', '-', '-', '-', '-'])
            simp = pattern.sub('', word)
            if len(simp) > 0:
                ow.write(simp.lower() + ' ')
            i += 1
    f.close()
    fc.close()
    ow.close()


def main(inf, outco, outwv, codir, wvdir):
    main_(inf,
          os.path.join(codir,
                       os.path.splitext(os.path.basename(outco))[0]) + '.txt',
          os.path.splitext(os.path.join(wvdir,
                                        os.path.basename(outwv)))[0] + '.txt')
