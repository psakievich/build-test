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
from urllib2 import urlopen
import subprocess
from glob import glob
from shutil import rmtree

# Functions
def url_ok(url):
    r = urlopen(url).getcode()
    return r == 200

def ReadInputParams(fileName):
    # preload optional input file values
    output = {
            "flags":"",
            "variants":"",
            "rootdir":os.environ["HOME"]
            }
    with open(fileName, 'r') as f:
        data = f.readlines()
    for line in data:
        temp = line.strip().split(":")
        # skip blank lines
        if len(temp)<=1:
            continue
        key = temp[0].lower().strip()
        value = temp[1].strip()
        output[key] = value
    return output
    
def SystemCall(command):
    try:
        #subprocess.check_call(command)
        os.system(command)
    except:
        print("Error with command: {cmd}".format(cmd=command))
        exit()

def CloneRepo( repoUrl, repoDest):
    if url_ok(repoUrl):
        CheckDirectory(repoDest, True)
        SystemCall("git clone --recursive {repo} {dest}".format(
            repo=repoUrl, dest=repoDest))
    else:
        raise Exception("Repo Url not found: {url}".format(url=repoUrl))

def UpdateRepo(repoDir, remote, branch):
    cwd = os.getcwd()
    try:
        os.chdir(repoDir)
        SystemCall("git fetch {rem} {br}".format(rem=remote, br=branch))
        SystemCall("git pull --rebase {rem} {br}".
            format(rem=remote, br=branch))
    except OSError as error:
        raise error 
    except subprocess.CalledProcessError as error:
        os.chdir(cwd)
        raise error
    except:
        os.chdir(cwd)
        raise Exception("Something unexpected went wrong when updating "
                "the git repo at {rep".format(rep=repoDir))
    os.chdir(cwd)

def CheckDirectory(dirName, create_it=False):
    exists = os.path.isdir(dirName)
    if exists is False and create_it is True:
        os.makedirs(dirName)
        return True
    return exists

def CloneNaluWindRepos(baseLocation):
    packages ={"https://github.com/spack/spack.git":baseLocation + "/spack",
            "https://github.com/Exawind/nalu-wind.git":baseLocation + "/nalu-wind"}
    for url, repoDest in packages.items():
        if CheckDirectory(repoDest) is False:
            CloneRepo(url,repoDest)

def SpackBuildPackage(spackLocation, machine, operatingSystem,
        package, flags=[], variants=[]):
    spackCommand = spackLocation+"/bin/spack install"
    CheckDirectory(spackLocation+r"/etc/spack/{os}".format(os=operatingSystem),
            True)
    for f in glob(r"configs/machines/base/*.yaml"):
        copy2(f, spackLocation+r"/etc/spack/")
    for f in glob(r"configs/machines/{machine}/*.yaml".format(machine=machine)):
        copy2(f, spackLocation+r"/etc/spack/{os}/".format(os=operatingSystem))
    for f in glob(r"configs/machines/{machine}/*.yaml.{machine}".format(
        machine=machine)):
        newFile = f.strip(r"configs/machines/{machine}".format(machine=machine))
        newFile = newFile.strip(".{machine}".format(machine=machine))
        copy2(f, spackLocation+r"/etc/spack/{os}/".format(os=operatingSystem)+newFile)
    executionCall = " ".join([spackCommand]+[flags]+[package]+[variants])
    print executionCall
    SystemCall(executionCall)

def BuildNaluWindSpack(configFile):
    params = ReadInputParams(configFile)
    baseLocation = params["rootdir"]+"/"+params["machine"]+"/"
    if params["wipe_directories"] is True:
        rmtree(baseLocation)
    CloneNaluWindRepos(baseLocation)
    SpackBuildPackage(baseLocation+"spack", params["machine"], params["os"],
            "nalu-wind", params["flags"], params["variants"])

if __name__=="__main__":
    if len(sys.argv) < 2:
        print("Please pass a configuration file.")
        print(sys.argv)
        exit(1)
    else:
        configFile = sys.argv[1]
    BuildNaluWindSpack(configFile)