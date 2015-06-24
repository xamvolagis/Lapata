# import pyximport; pyximport.install()
import tuebingenparser
import argparse
import os
parser = argparse.ArgumentParser(description="Compute the SYNTF Baseline")
parser.add_argument('input')
parser.add_argument('out-conll')
parser.add_argument('out-word2vec')
parser.add_argument('dir-conll')
parser.add_argument('dir-word2vec')
parser.add_argument('--recursive', dest='recursive', action='store_true')
parser.add_argument('--quiet', dest='verbose', action='store_true')

parser.set_defaults(recursive=False)
parser.set_defaults(verbose=False)


def main(inputs, v):
    for inp in inputs:
        tuebingenparser.main(inp,
                             inp,
                             inp,
                             v['dir-conll'],
                             v['dir-word2vec'])

if __name__ == '__main__':
    args = parser.parse_args()
    v = vars(args)
    if v['recursive']:
        inputs = []
        for root, dirs, files in os.walk(v['input']):
            for f in files:
                inputs.append(os.path.join(root, f))
    else:
        inputs = v['recursive']
    main(inputs, v)


