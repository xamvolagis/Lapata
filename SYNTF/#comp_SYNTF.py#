# import pyximport; pyximport.install()
import SYNTF
import argparse
parser = argparse.ArgumentParser(description="Compute the SYNTF Baseline")
parser.add_argument('input')
parser.add_argument('output')
parser.add_argument('language')
parser.add_argument('numrels')
parser.add_argument('--score', dest='score', action='store_true')
parser.add_argument('--no-score', dest='score', action='store_false')
parser.add_argument('--multi', dest='multi', action='store_true')
parser.add_argument('--no-multi', dest='multi', action='store_false')


parser.set_defaults(score=True)
parser.set_defaults(multi=False)

if __name__ == '__main__':
    args = parser.parse_args()
    v = vars(args)
    SYNTF.main(v['input'],
               v['output'],
               LANG=v['language'],
               NSYPOS=int(v['numrels']),
               SCORE=v['score'],
               MULTI=v['multi'])
