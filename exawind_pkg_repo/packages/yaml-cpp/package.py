# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.spec import ConflictsInSpecError
from spack.pkg.builtin.yaml_cpp import YamlCpp as bYamlCpp


yaml_cpp_tests_libcxx_error_msg = 'yaml-cpp tests incompatible with libc++'


class YamlCpp(bYamlCpp):
    version('0.6.3', sha256='77ea1b90b3718aa0c324207cb29418f5bced2354c2e483a9523d98c3460af1ed')
