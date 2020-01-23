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
from spack.pkg.builtin.openfast import Openfast as bOpenfast

class Openfast(bOpenfast):
    def cmake_args(self):
        spec = self.spec

        options = []

        options.extend(super(Openfast, self).cmake_args())

        if '+cxx' in spec:
            options.extend([
                "-DCMAKE_CXX_FLAGS=-D DBG_OUTS",
                "-DCMAKE_Fortran_FLAGS=-D DBG_OUTS",
            ])
        return options

