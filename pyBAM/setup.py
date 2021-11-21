#!/usr/bin/env python
#-----------------------------------------------------------------------------#
#           Group on Data Assimilation Development - GDAD/CPTEC/INPE          #
#-----------------------------------------------------------------------------#
#BOP
#
# !SCRIPT:
#
# !DESCRIPTION:
#
# !CALLING SEQUENCE:
#
# !REVISION HISTORY: 
# 10 Nov 2021 - J. G. de Mattos - Initial Version
#
# !REMARKS:
#
#EOP
#-----------------------------------------------------------------------------#
#BOC
import os
import setuptools
from numpy.distutils.core import Extension

try:
    sigiobamPath=os.environ['SIGIOBAM']
except:
    print('')
    print('ERROR: Unknown where is sigioBAM library!')
    print('       please set SIGIOBAM variable!')
    print('')
    exit()
    
ext  = Extension(name = 'pythonBAM',
                 extra_f77_compile_args=["-fconvert=big-endian"],
                 extra_f90_compile_args=["-fconvert=big-endian"],
                 extra_link_args=["-fconvert=big-endian"],
                 include_dirs=[sigiobamPath+"/include"],
                 library_dirs=[sigiobamPath+"/lib"],
                 libraries=["sigiobam"],
                 sources=['pyBAM/f90/pythonBAM.f90','pyBAM/f90/pythonBAM.pyf'])

if __name__ == "__main__":
    from numpy.distutils.core import setup
    setup(name         = 'pyBAM',
          version      = '1.0',
          description  = "Read and plot BAM spectral files",
          author       = "Joao Gerd Z. de Mattos",
          author_email = "joao.gerd@inpe.br",
          packages=['pyBAM'],
          install_requires=["numpy","matplotlib",'basemap'],
          platforms = ["any"],
          ext_modules = [ext],
          zip_safe = False
          )

#EOC
#-----------------------------------------------------------------------------#

