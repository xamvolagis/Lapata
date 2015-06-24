from setuptools import setup
from Cython.Build import cythonize

package = 'tuebingen'
version = '0.1'

setup(name=package,
      version=version,
      description="Preprocesses tuebingen data",
      ext_modules=cythonize("tuebingenparser.pyx")
      )
