#!/bin/bash

#Script for copying the recommended configuration for Spack onto your system
#for building Nalu, be it on Peregrine, Merlin, Cori, or a Mac

if [ -z "${SPACK_ROOT}" ]; then
    echo "SPACK_ROOT must be set first"
    exit 1
fi

set -ex

OS=`uname -s`

# Find machine
if [ ${OS} == 'Darwin' ]; then
  MACHINE=mac
  OSX=`sw_vers -productVersion`
  case "${OSX}" in
    10.12*)
      MACHINE=mac_sierra
    ;;
  esac
elif [ ${OS} == 'Linux' ]; then
  case "${NERSC_HOST}" in
    cori)
      MACHINE=cori
    ;;
    "")
      MYHOSTNAME=`grep merlin /etc/nrel`
      case "${MYHOSTNAME}" in
        *merlin)
          MACHINE=merlin
        ;;
        "")
          MYHOSTNAME=`hostname -d`
          case "${MYHOSTNAME}" in
            hpc.nrel.gov)
              MACHINE=peregrine
            ;;
          esac
        ;;
      esac
    ;;
  esac
fi

# Copy machine-specific configuration for Spack if we recognize the machine
if [ ${MACHINE} == 'peregrine' ] || [ ${MACHINE} == 'merlin' ] || [ ${MACHINE} == 'cori' ]; then
  cp config.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/config.yaml
  cp packages.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/packages.yaml
  cp compilers.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/compilers.yaml
  if [ ${MACHINE} == 'merlin' ]; then
    cp intel.cfg.${MACHINE} ${SPACK_ROOT}/etc/spack/intel.cfg
  fi
  # Use branch instead of tag so spack will checkout 
  # a real git repo instead of cache a tar.gz of a branch
  sed -i "s/tag=/branch=/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py
elif [ ${MACHINE} == 'mac' ]; then
  cp packages.yaml.${MACHINE} ${SPACK_ROOT}/etc/spack/packages.yaml
  # Use branch instead of tag so spack will checkout 
  # a real git repo instead of cache a tar.gz of a branch
  sed -i "" -e "s/tag=/branch=/g" ${SPACK_ROOT}/var/spack/repos/builtin/packages/trilinos/package.py
else
  echo "Machine name not found"
fi

#cp -R openfast ${SPACK_ROOT}/var/spack/repos/builtin/packages/
#cp -R tioga ${SPACK_ROOT}/var/spack/repos/builtin/packages/
#cp -R nalu ${SPACK_ROOT}/var/spack/repos/builtin/packages/
