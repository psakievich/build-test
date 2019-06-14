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
from urllib import urlopen

def url_ok(url):
    r = urlopen(url).getcode()
    return r == 200

# Global parameters
ROOTDIR = os.environ["HOME"]
COMPILER = r"gcc@7.2.0"

# Functions
def ReadInputParams(fileName):
    f = open(fileName, 'r')
    output = {}
    for line in f:
        temp = line.strip().split(":")
        output[temp[0].lower().strip()]=temp[1].strip()
    return output
    
def SystemCall(command):
    # TODO Move this to subprocess and pipe output to logfile
    print("System Call: "+command)
    os.system(command)

def CloneRepo( repoUrl, repoDest=''):
    if url_ok(repoUrl):
        SystemCall("git clone --recursive {repo} {dest}".format(repo=repoUrl, dest=repoDest))
    else:
        raise Exception("Repo Url not found: {url}".format(url=repoUrl))

def UpdateRepo(repo, remote, branch):
    pass

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
    if len(sys.argv) < 2:
        print("Please pass a configuration file.")
        print(sys.argv)
        exit(1)
    else:
        configFile = sys.argv[1]
    params = ReadInputParams(configFile)
    baseLocation = CreateDirectories(params["machine"])
    CloneRepos(baseLocation)
    SetupSpackVariants(baseLocation+"spack",machine)
    BuildNaluWind()