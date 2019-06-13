#!/usr/bin/env/ python
########################################################
#
#  This script is a template for building nalu-wind
#  with catalyst support from scratch
#
########################################################
import os
import sys
from shutil import copy2

# Global parameters
ROOTDIR = os.environ["HOME"]
COMPILER = r"gcc@7.2.0"
PVVERSION = r"v5.6.0"

# Functions
def SystemCall(command):
    # TODO Move this to subprocess and pipe output to logfile
    print("System Call: "+command)
    os.system(command)

def CloneRepo( repoUrl, repoDest=''):
    SystemCall("git clone  --recursive {repo} {dest}".format(repo=repoUrl, dest=repoDest))

def CheckDirectory(dirName, create_it=False):
    exists = os.path.isdir(dirName)
    if exists is False and create_it is True:
        os.makedirs(dirName)
        return True
    return exists

def CreateDirectories(machine):
    baseLocation = ROOTDIR + "/" + machine + "/"
    CheckDirectory(baseLocation, create_it=True)
    return baseLocation

def CloneRepos(baseLocation):
    packages ={"https://github.com/spack/spack.git":baseLocation + "/spack",
      "git@github.com:Exawind/nalu-wind.git":baseLocation + "/nalu-wind"}
    for url, repoDest in packages.items():
        if CheckDirectory(repoDest) is False:
            CloneRepo(url,repoDest)

def UpdateRepo(repo, remote, branch):
    pass

def SetupSpackVariants(spackLocation, machine, options=[]):
    spackCommand = spackLocation+"/bin/spack"
    copy2(machine+"/packages.yaml",spackLocation+"/etc/spack")
    copy2(machine+"/config.yaml",spackLocation+"/etc/spack")
    executionCall = spackCommand + r" install --dirty nalu-wind%{compiler} +openfast ^trilinos@develop".format(compiler=COMPILER)
    for o in options:
        executionCall += " " + o
    SystemCall(executionCall)

def BuildNaluWind():
    pass

if __name__=="__main__":
    machine = 'default'
    # TODO parse from file
    if len(sys.argv) < 2:
        print("Please pass the machine type as an argument")
        print(sys.argv)
        exit(1)
    else:
        machine = sys.argv[1]
    baseLocation = CreateDirectories(machine)
    CloneRepos(baseLocation)
    SetupSpackVariants(baseLocation+"spack",machine)
    BuildParaview(machine)
    BuildCatalyst(machine)
    BuildNaluWind()