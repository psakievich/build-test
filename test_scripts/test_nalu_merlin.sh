#!/bin/bash -l

#PBS -N test_nalu_merlin
#PBS -l nodes=1:ppn=24,walltime=8:00:00
#PBS -A windFlowModeling
#PBS -q batch
#PBS -j oe
#PBS -W umask=002

# Script for running regression tests on Merlin using Spack and submitting results to CDash

echo `date`
echo ------------------------------------------------------
echo "Job is running on node ${HOSTNAME}"
echo ------------------------------------------------------
if [ ! -z "${PBS_JOBID}" ]; then
  echo PBS: Qsub is running on ${PBS_O_HOST}
  echo PBS: Originating queue is ${PBS_O_QUEUE}
  echo PBS: Executing queue is ${PBS_QUEUE}
  echo PBS: Working directory is ${PBS_O_WORKDIR}
  echo PBS: Execution mode is ${PBS_ENVIRONMENT}
  echo PBS: Job identifier is ${PBS_JOBID}
  echo PBS: Job name is ${PBS_JOBNAME}
  echo PBS: Node file is ${PBS_NODEFILE}
  echo PBS: Current home directory is ${PBS_O_HOME}
  echo PBS: PATH = ${PBS_O_PATH}
  echo ------------------------------------------------------
fi
printf "\n\n"

# Set nightly directory and Nalu checkout directory
NALU_TESTING_DIR=/projects/windFlowModeling/ExaWind/NaluNightlyTesting
NALU_DIR=${NALU_TESTING_DIR}/Nalu

# Set host name to pass to CDash
HOST_NAME="merlin.hpc.nrel.gov"

# Set spack location
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

# Uncomment this if statement to create and set up
# a testing directory if it doesn't exist
#if [ ! -d "${NALU_TESTING_DIR}" ]; then
#  mkdir -p ${NALU_TESTING_DIR}
#
#  # Create and set up nightly directory with Spack installation
#  printf "\n\nCloning Spack repo...\n\n"
#  git clone https://github.com/LLNL/spack.git ${SPACK_ROOT}
#
#  # Configure Spack for Peregrine
#  printf "\n\nConfiguring Spack...\n\n"
#  cd ${NALU_TESTING_DIR} && git clone https://github.com/NaluCFD/NaluSpack.git
#  cd ${NALU_TESTING_DIR}/NaluSpack/spack_config
#  ./copy_config.sh
#
#  # Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
#  printf "\n\nCloning Nalu repo...\n\n"
#  git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR}
#
#  # Create a jobs directory
#  printf "\n\nMaking job output directory...\n\n"
#  mkdir -p ${NALU_TESTING_DIR}/jobs
#fi

# Load Spack
. ${SPACK_ROOT}/share/spack/setup-env.sh

TPLS="
^openmpi@1.10.3 \
^boost@1.60.0 \
^cmake@3.6.1 \
^parallel-netcdf@1.6.1 \
^hdf5@1.8.16 \
^netcdf@4.3.3.1 \
^pkg-config@0.29.2 \
^zlib@1.2.11 \
^hwloc@1.11.6 \
^m4@1.4.17 \
^superlu@4.3
"

# Test Nalu for trilinos master, develop
for TRILINOS_BRANCH in master #develop
do
  # Test Nalu for intel, gcc
  for COMPILER_NAME in gcc intel
  do
    printf "\n\nTesting Nalu with ${COMPILER_NAME} and Trilinos ${TRILINOS_BRANCH}.\n\n"

    # Change to Nalu testing directory
    cd ${NALU_TESTING_DIR}

    # Load necessary modules
    printf "\n\nLoading modules...\n\n"
    module purge
 
    # Uninstall Nalu and Trilinos; it's an error if they don't exist yet, but we skip it
    printf "\n\nUninstalling Nalu and Trilinos...\n\n"
    spack uninstall -y nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH}
    spack uninstall -y nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}

    # For Intel compiler
    export TMPDIR=/dev/shm
    export INTEL_LICENSE_FILE=28518@hpc-admin1.hpc.nrel.gov
    for i in ICCCFG ICPCCFG IFORTCFG
    do
      export $i=${SPACK_ROOT}/etc/spack/intel.cfg
    done
    # End for Intel compiler

    printf "\n\nUpdating Nalu and Trilinos...\n\n"
    spack cd nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ${TPLS} && pwd && git fetch --all && git reset --hard origin/master && git clean -df && git status -uno
    spack cd nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME} ${TPLS} && pwd && git fetch --all && git reset --hard origin/${TRILINOS_BRANCH} && git clean -df && git status -uno

    printf "\n\nInstalling Nalu using ${COMPILER_NAME}...\n\n"
    spack install --keep-stage nalu %${COMPILER_NAME} ^nalu-trilinos@${TRILINOS_BRANCH} ${TPLS}

    # Set permissions after install
    chmod -R go-w `spack location -i nalu %${COMPILER_NAME}`
    chmod -R go-w `spack location -i nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}`
    #chmod -R go-w ${NALU_TESTING_DIR}/spack/opt

    # Load spack built cmake and openmpi into path
    printf "\n\nLoading Spack modules into environment...\n\n"
    # Refresh available modules (this is only really necessary on the first run of this script
    # because cmake and openmpi will already have been built and module files registered in subsequent runs)
    . ${SPACK_ROOT}/share/spack/setup-env.sh
    spack load cmake %${COMPILER_NAME}
    spack load openmpi %${COMPILER_NAME}

    # Set the Trilinos and Yaml directories to pass to ctest
    printf "\n\nSetting variables to pass to CTest...\n\n"
    TRILINOS_DIR=`spack location -i nalu-trilinos@${TRILINOS_BRANCH} %${COMPILER_NAME}`
    YAML_DIR=`spack location -i yaml-cpp %${COMPILER_NAME}`

    # Set the extra identifiers for CDash build description
    EXTRA_BUILD_NAME="-${COMPILER_NAME}-trlns_${TRILINOS_BRANCH}"

    # Change to Nalu build directory
    cd ${NALU_DIR}/build

    # Clean build directory; checkout if NALU_DIR is not blank first
    if [ ! -z "${NALU_DIR}" ]; then
      printf "\n\nCleaning build directory...\n\n"
      rm -rf ${NALU_DIR}/build/*
    fi

    # Run ctest
    printf "\n\nRunning CTest...\n\n"
    ctest \
      -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
      -DYAML_DIR=${YAML_DIR} \
      -DTRILINOS_DIR=${TRILINOS_DIR} \
      -DHOST_NAME=${HOST_NAME} \
      -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} \
      -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake
    printf "\n\nReturned from CTest...\n\n"

    # Remove spack built cmake and openmpi from path
    printf "\n\nUnloading Spack modules from environment...\n\n"
    spack unload cmake %${COMPILER_NAME}
    spack unload openmpi %${COMPILER_NAME}

    # Clean TMPDIR before exiting
    if [ ! -z "${TMPDIR}" ]; then
      printf "\n\nCleaning TMPDIR directory...\n\n"
      rm -rf ${TMPDIR}/*
      unset TMPDIR
    fi

    printf "\n\nDone testing Nalu with ${COMPILER_NAME} and Trilinos ${TRILINOS_BRANCH}.\n\n"
  done
done
