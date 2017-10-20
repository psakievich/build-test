#!/bin/bash -l

# Script for running nightly regression tests for Nalu on a particular set 
# of machines using Spack and submitting results to CDash

verbose=true
execute=false

doCmd() {
  #if $verbose; then echo "\$ ${@/eval/}"; fi
  #if $verbose; then echo "+ $@"; fi
  if $verbose; then echo "+ ${@/eval/}"; fi
  #if $execute; then "$@"; fi
}

printf "$(date)\n"
printf "======================================================\n"
printf "Job is running on ${HOSTNAME}\n"
printf "======================================================\n"
if [ ! -z "${PBS_JOBID}" ]; then
  printf "PBS: Qsub is running on ${PBS_O_HOST}\n"
  printf "PBS: Originating queue is ${PBS_O_QUEUE}\n"
  printf "PBS: Executing queue is ${PBS_QUEUE}\n"
  printf "PBS: Working directory is ${PBS_O_WORKDIR}\n"
  printf "PBS: Execution mode is ${PBS_ENVIRONMENT}\n"
  printf "PBS: Job identifier is ${PBS_JOBID}\n"
  printf "PBS: Job name is ${PBS_JOBNAME}\n"
  printf "PBS: Node file is ${PBS_NODEFILE}\n"
  printf "PBS: Current home directory is ${PBS_O_HOME}\n"
  printf "PBS: PATH = ${PBS_O_PATH}\n"
  printf "======================================================\n"
fi
printf "\n"

if [ $# -ne 1 ]; then
    printf "$0: usage: $0 <machine>\n"
    exit 1
else
  MACHINE_NAME="$1"
fi

HOST_NAME="${MACHINE_NAME}.hpc.nrel.gov"

# Set configurations to test for each machine
if [ ${MACHINE_NAME} == 'peregrine' ]; then
  declare -a LIST_OF_BUILD_TYPES=("Release")
  declare -a LIST_OF_TRILINOS_BRANCHES=("develop")
  declare -a LIST_OF_COMPILERS=("gcc" "intel")
  declare -a LIST_OF_GCC_COMPILERS=("5.2.0")
  declare -a LIST_OF_INTEL_COMPILERS=("17.0.2")
  declare -a LIST_OF_TPLS=("openfast")
  NALU_TESTING_DIR=/projects/windFlowModeling/ExaWind/NaluNightlyTesting
elif [ ${MACHINE_NAME} == 'merlin' ]; then
  declare -a LIST_OF_BUILD_TYPES=("Release")
  declare -a LIST_OF_TRILINOS_BRANCHES=("develop")
  declare -a LIST_OF_COMPILERS=("gcc" "intel")
  declare -a LIST_OF_GCC_COMPILERS=("4.9.2")
  declare -a LIST_OF_INTEL_COMPILERS=("17.0.2")
  declare -a LIST_OF_TPLS=("openfast")
  NALU_TESTING_DIR=${HOME}/NaluNightlyTesting
elif [ ${MACHINE_NAME} == 'mac' ]; then
  declare -a LIST_OF_BUILD_TYPES=("Release")
  declare -a LIST_OF_TRILINOS_BRANCHES=("develop" "master")
  declare -a LIST_OF_COMPILERS=("gcc" "clang")
  declare -a LIST_OF_GCC_COMPILERS=("7.2.0")
  declare -a LIST_OF_CLANG_COMPILERS=("9.0.0-apple")
  declare -a LIST_OF_TPLS=("openfast")
  NALU_TESTING_DIR=${HOME}/NaluNightlyTesting
else
  printf "\nMachine name not recognized.\n\n"
fi

NALU_DIR=${NALU_TESTING_DIR}/Nalu
NALUSPACK_DIR=${NALU_TESTING_DIR}/NaluSpack
export SPACK_ROOT=${NALU_TESTING_DIR}/spack

printf "\nNALU_TESTING_DIR: ${NALU_TESTING_DIR}\n"
printf "\nHOST_NAME: ${HOST_NAME}\n"
printf "\nNALU_DIR: ${NALU_DIR}\n"
printf "\nNALUSPACK_DIR: ${NALU_DIR}\n"
printf "\nSPACK_ROOT: ${SPACK_ROOT}\n"

# Create and set up the entire testing directory if it doesn't exist
if [ ! -d "${NALU_TESTING_DIR}" ]; then
  printf "\n\nTop level testing directory doesn't exist. Creating everything from scratch...\n\n"

  # Make top level testing directory
  printf "\n\nCreating top level testing directory...\n\n"
  doCmd mkdir -p ${NALU_TESTING_DIR}

  # Create and set up nightly directory with Spack installation
  printf "\n\nCloning Spack repo...\n\n"
  doCmd git clone https://github.com/LLNL/spack.git ${SPACK_ROOT}
  # Nalu v1.2.0 matching sha-1 for Spack
  # doCmd eval "cd ${SPACK_ROOT} && git checkout d3e4e88bae2b3ddf71bf56da18fe510e74e020b2"

  # Configure Spack for Peregrine
  printf "\n\nConfiguring Spack...\n\n"
  doCmd git clone https://github.com/NaluCFD/NaluSpack.git ${NALUSPACK_DIR}
  # Nalu v1.2.0 matching tag for NaluSpack
  #doCmd cd ${NALUSPACK_DIR} && git checkout v1.2.0
  doCmd eval "cd ${NALUSPACK_DIR}/spack_config && ./setup_spack.sh"

  # Checkout Nalu and meshes submodule outside of Spack so ctest can build it itself
  printf "\n\nCloning Nalu repo...\n\n"
  doCmd git clone --recursive https://github.com/NaluCFD/Nalu.git ${NALU_DIR}
  # Nalu v1.2.0 tag
  #doCmd eval "cd ${NALU_DIR} && git checkout v1.2.0"

  # Create a jobs directory
  printf "\n\nMaking job output directory...\n\n"
  doCmd mkdir -p ${NALU_TESTING_DIR}/jobs
fi

# Load Spack
printf "\n\nLoading Spack...\n\n"
doCmd source ${SPACK_ROOT}/share/spack/setup-env.sh

printf "\n\nStarting testing loops...\n\n"
printf "\n============================================================\n"
doCmd source ${SPACK_ROOT}/share/spack/setup-env.sh
# Test Nalu for the list of trilinos branches
for TRILINOS_BRANCH in "${LIST_OF_TRILINOS_BRANCHES[@]}"; do
  # Test Nalu for the list of compilers
  for COMPILER_NAME in "${LIST_OF_COMPILERS[@]}"; do

    # Move specific compiler version to generic compiler version
    if [ ${COMPILER_NAME} == 'gcc' ]; then
      declare -a COMPILER_VERSIONS=("${LIST_OF_GCC_COMPILERS[@]}")
    elif [ ${COMPILER_NAME} == 'intel' ]; then
      declare -a COMPILER_VERSIONS=("${LIST_OF_INTEL_COMPILERS[@]}")
    elif [ ${COMPILER_NAME} == 'clang' ]; then
      declare -a COMPILER_VERSIONS=("${LIST_OF_CLANG_COMPILERS[@]}")
    fi

    # Test Nalu for the list of compiler versions
    for COMPILER_VERSION in "${COMPILER_VERSIONS[@]}"; do

      printf "\n************************************************************\n"
      printf "\nTesting Nalu with:\n"
      printf "${COMPILER_NAME}@${COMPILER_VERSION}\n"
      printf "trilinos@${TRILINOS_BRANCH}\n"
      printf "at $(date).\n\n"

      # Define TRILINOS and GENERAL_CONSTRAINTS from a single location for all scripts
      doCmd unset GENERAL_CONSTRAINTS
      doCmd source ${NALU_TESTING_DIR}/NaluSpack/spack_config/shared_constraints.sh
      printf "\n\nUsing constraints: ${GENERAL_CONSTRAINTS}\n\n"

      # Change to Nalu testing directory
      doCmd cd ${NALU_TESTING_DIR}

      # Load necessary modules
      printf "\n\nLoading modules...\n\n"
      if [ ${MACHINE_NAME} == 'peregrine' ]; then
        {
        doCmd module purge
        doCmd module load gcc/5.2.0
        doCmd module load python/2.7.8
        doCmd module unload mkl
        } &> /dev/null
      elif [ ${MACHINE_NAME} == 'merlin' ]; then
        doCmd module purge
        doCmd module load GCCcore/4.9.2
      fi

      # Turn off OpenMP if using clang
      if [ ${COMPILER_NAME} == 'clang' ]; then
        TRILINOS=$(sed 's/+openmp/~openmp/g' <<<"${TRILINOS}")
      fi
 
      # Uninstall Trilinos; it's an error if it doesn't exist yet, but we skip it
      printf "\n\nUninstalling Trilinos...\n\n"
      doCmd spack uninstall -y ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS}

      if [ ${MACHINE_NAME} == 'peregrine' ]; then
        if [ ${COMPILER_NAME} == 'gcc' ]; then
          # Fix for Peregrine's broken linker for gcc
          printf "\n\nInstalling binutils...\n\n"
          doCmd spack install binutils %${COMPILER_NAME}@${COMPILER_VERSION}
          printf "\n\nReloading Spack...\n\n"
          doCmd source ${SPACK_ROOT}/share/spack/setup-env.sh
          printf "\n\nLoading binutils...\n\n"
          doCmd spack load binutils %${COMPILER_NAME}@${COMPILER_VERSION}
        elif [ ${COMPILER_NAME} == 'intel' ]; then
          printf "\n\nSetting up rpath for Intel...\n\n"
          # For Intel compiler to include rpath to its own libraries
          for i in ICCCFG ICPCCFG IFORTCFG
          do
            doCmd export $i=${SPACK_ROOT}/etc/spack/intel.cfg
          done
        fi
      elif [ ${MACHINE_NAME} == 'merlin' ]; then
        if [ ${COMPILER_NAME} == 'intel' ]; then
          # For Intel compiler to include rpath to its own libraries
          doCmd export INTEL_LICENSE_FILE=28518@hpc-admin1.hpc.nrel.gov
          for i in ICCCFG ICPCCFG IFORTCFG
          do
            doCmd export $i=${SPACK_ROOT}/etc/spack/intel.cfg
          done
        fi
      fi

      # Set the TMPDIR to disk so it doesn't run out of space
      if [ ${MACHINE_NAME} == 'peregrine' ]; then
        printf "\n\nMaking and setting TMPDIR to disk...\n\n"
        doCmd mkdir -p /scratch/${USER}/.tmp
        doCmd export TMPDIR=/scratch/${USER}/.tmp
      elif [ ${MACHINE_NAME} == 'merlin' ]; then
        doCmd export TMPDIR=/dev/shm
      fi

      # Update Trilinos
      printf "\n\nUpdating Trilinos...\n\n"
      doCmd eval "spack cd ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS} && pwd && git fetch --all && git reset --hard origin/${TRILINOS_BRANCH} && git clean -df && git status -uno"

      # Install all Nalu dependencies
      printf "\n\nInstalling Nalu dependencies using ${COMPILER_NAME}@${COMPILER_VERSION}...\n\n"
      TPL_VARIANTS=""
      for TPL in "${LIST_OF_TPLS[@]}"; do
        TPL_VARIANTS+="+${TPL}"
      done
      doCmd spack install --keep-stage --only dependencies nalu ${TPL_VARIANTS} %${COMPILER_NAME}@${COMPILER_VERSION} ^${TRILINOS}@${TRILINOS_BRANCH} ${GENERAL_CONSTRAINTS}

      # Delete all the staged files except Trilinos
      STAGE_DIR=$(spack location -S)
      if [ ! -z "${STAGE_DIR}" ]; then
        #Haven't been able to find another robust way to rm with exclude
        doCmd eval "cd ${STAGE_DIR} && rm -rf a* b* c* d* e* f* g* h* i* j* k* l* m* n* o* p* q* r* s* tar* u* v* w* x* y* z*"
        #find ${STAGE_DIR}/ -maxdepth 0 -type d -not -name "trilinos*" -exec rm -r {} \;
      fi

      if [ ${MACHINE_NAME} == 'peregrine' ]; then
        if [ ${COMPILER_NAME} == 'intel' ]; then
          printf "\n\nLoading Intel compiler module for CTest...\n\n"
          doCmd module load comp-intel/2017.0.2
        fi
      fi

      # Load spack built cmake and openmpi into path
      printf "\n\nLoading Spack modules into environment...\n\n"
      # Refresh available modules (this is only really necessary on the first run of this script
      # because cmake and openmpi will already have been built and module files registered in subsequent runs)
      doCmd source ${SPACK_ROOT}/share/spack/setup-env.sh
      if [ ${MACHINE_NAME} == 'mac' ]; then
        doCmd export PATH=$(spack location -i cmake %${COMPILER_NAME}@${COMPILER_VERSION})/bin:${PATH}
        doCmd export PATH=$(spack location -i openmpi %${COMPILER_NAME}@${COMPILER_VERSION})/bin:${PATH}
      else
        doCmd spack load cmake %${COMPILER_NAME}@${COMPILER_VERSION}
        doCmd spack load openmpi %${COMPILER_NAME}@${COMPILER_VERSION}
      fi

      # Set the Trilinos and Yaml directories to pass to ctest
      printf "\n\nSetting variables to pass to CTest...\n\n"
      TRILINOS_DIR=$(spack location -i ${TRILINOS}@${TRILINOS_BRANCH} %${COMPILER_NAME}@${COMPILER_VERSION} ${GENERAL_CONSTRAINTS})
      YAML_DIR=$(spack location -i yaml-cpp %${COMPILER_NAME}@${COMPILER_VERSION})

      for BUILD_TYPE in "${LIST_OF_BUILD_TYPES[@]}"; do

        # Set the extra identifiers for CDash build description
        #BUILD_TYPE_LOWERCASE="$(tr [A-Z] [a-z] <<< "${BUILD_TYPE}")"
        #EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}-trlns_${TRILINOS_BRANCH}-${BUILD_TYPE_LOWERCASE}"
        EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}-trlns_${TRILINOS_BRANCH}"

        # Clean build directory; check if NALU_DIR is blank first
        if [ ! -z "${NALU_DIR}" ]; then
          printf "\n\nCleaning build directory...\n\n"
          doCmd rm -rf ${NALU_DIR}/build/*
        fi

        # Set warning flags for build
        WARNINGS="-Wall"
        doCmd export CXXFLAGS="${WARNINGS}"
        doCmd export CFLAGS="${WARNINGS}"
        doCmd export FFLAGS="${WARNINGS}"

        # Run ctest
        printf "\n\nRunning CTest at $(date)...\n\n"
        # Change to Nalu build directory
        doCmd cd ${NALU_DIR}/build
        doCmd export OMP_NUM_THREADS=1
        doCmd export OMP_PROC_BIND=false
        doCmd ctest \
          -DNIGHTLY_DIR=${NALU_TESTING_DIR} \
          -DYAML_DIR=${YAML_DIR} \
          -DTRILINOS_DIR=${TRILINOS_DIR} \
          -DHOST_NAME=${HOST_NAME} \
          -DBUILD_TYPE=${BUILD_TYPE} \
          -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} \
          -VV -S ${NALU_DIR}/reg_tests/CTestNightlyScript.cmake
        printf "\n\nReturned from CTest at $(date)...\n\n"
      done

      # Remove spack built cmake and openmpi from path
      printf "\n\nUnloading Spack modules from environment...\n\n"
      if [ ${MACHINE_NAME} != 'mac' ]; then
        doCmd spack unload cmake %${COMPILER_NAME}@${COMPILER_VERSION}
        doCmd spack unload openmpi %${COMPILER_NAME}@${COMPILER_VERSION}
      elif [ ${MACHINE_NAME} == 'peregrine' ]; then
        if [ ${COMPILER_NAME} == 'gcc' ]; then
          doCmd spack unload binutils %${COMPILER_NAME}@${COMPILER_VERSION}
        fi
        #unset TMPDIR
      fi

      printf "\n\nDone testing Nalu with:\n"
      printf "${COMPILER_NAME}@${COMPILER_VERSION}\n"
      printf "trilinos@${TRILINOS_BRANCH}\n"
      printf "at $(date).\n"
      printf "\n************************************************************\n\n"

    done
  done
done

# Clean TMPDIR before exiting
if [ ${MACHINE_NAME} == 'merlin' ]; then
  if [ ! -z "${TMPDIR}" ]; then
    printf "\n\nCleaning TMPDIR directory...\n\n"
    doCmd rm -rf /dev/shm/* &> /dev/null
    #doCmd rm -r ${TMPDIR}/* &> /dev/null
    doCmd unset TMPDIR
  fi
fi

#if [ ${MACHINE_NAME} != 'mac' ]; then
#  printf "\n\nSetting permissions...\n\n"
#  doCmd chmod -R a+rX,go-w ${NALU_TESTING_DIR}
#  doCmd chmod g+w ${NALU_TESTING_DIR}
#  doCmd chmod g+w ${NALU_TESTING_DIR}/spack
#  doCmd chmod g+w ${NALU_TESTING_DIR}/spack/opt
#  doCmd chmod g+w ${NALU_TESTING_DIR}/spack/opt/spack
#  doCmd chmod -R g+w ${NALU_TESTING_DIR}/spack/opt/spack/.spack-db
#fi

printf "\n$(date)\n"
printf "\n\nDone!\n\n"