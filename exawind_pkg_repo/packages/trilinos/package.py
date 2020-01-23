# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

# ----------------------------------------------------------------------------
# If you submit this package back to Spack as a pull request,
# please first remove this boilerplate and all FIXME comments.
#
# This is a template package file for Spack.  We've put "FIXME"
# next to all the things you'll want to change. Once you've handled
# them, you can save this file and test your package like this:
#
#     spack install exawind-trilinos
#
# You can edit this file again by typing:
#
#     spack edit exawind-trilinos
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *
from spack.pkg.builtin.trilinos import Trilinos as bTrilinos


class Trilinos(bTrilinos):
    def cmake_args(self):
        options = []
        options.extend(super(Trilinos, self).cmake_args())
        try:
            ind = options.index('-DTpetra_INST_INT_LONG_LONG:BOOL=ON')
            options[ind]='-DTpetra_INST_INT_LONG_LONG:BOOL=OFF'
        except:
            pass
        return options
