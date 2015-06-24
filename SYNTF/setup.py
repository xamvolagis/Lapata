from setuptools import setup
from Cython.Build import cythonize

package = 'SYNTF'
version = '0.1'

setup(name=package,
      version=version,
      description="Computes the SYNTF baseline",
      ext_modules=cythonize("SYNTF.pyx")
      )


