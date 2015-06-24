import gensim
import gensim.models.word2vec as wv
import sys
from itertools import product


def model_from_options(sentences, **kwargs):
    fname = "gensim"
    for key, value in kwargs.items():
        fname += "_{}-{!s}".format(key, value)
    print("training {}".format(fname))
    model = wv.Word2Vec(sentences, **kwargs)
    model.save(fname + ".model")


def main(sentences_file):
    """
    Currently, the variable ranges must be hand-edited in this file
    """
    sentences = wv.LineSentence(sentences_file)
    sg_range = range(2)
    size_range = range(100, 301, 25)
    window_range = range(3, 14, 2)
    rr = product(size_range,
                 window_range,
                 sg_range)
    for size, window, sg in rr:
        model_from_options(sentences, size=size, window=window, sg=sg)


if __name__ == '__main__':
    main(sys.argv[1])
