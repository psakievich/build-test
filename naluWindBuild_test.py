import unittest
import urllib2

try:
    import mock
except:
    import unittest.mock as mock
import naluWindBuild as nwb

class GeneralFunctionsMocks(unittest.TestCase):
    """
    This class defines a set of mocks that will operate
    like the filesystem.  This allows testing without 
    actually having to create directories and download files.
    All operations of the build and test script will only need
    the build-test directory, and a configuration file which will
    contain a valid ROOTDIR for the current file system.
    """
    def setUp(self):
        self.ROOTDIR = "/HOME"
        self.CWD = self.ROOTDIR
        self.dirList = [self.ROOTDIR]
        #define mocks
        self.mock_isdir_patch = mock.patch("naluWindBuild.os.path.isdir")
        self.mock_makedirs_patch = mock.patch("naluWindBuild.os.makedirs")
        self.mock_sys_call_patch = mock.patch(
                "naluWindBuild.os.system")
        self.mock_chdir_patch = mock.patch("naluWindBuild.os.chdir")
        self.mock_getcwd_patch = mock.patch("naluWindBuild.os.getcwd")
        # start mocks for this object
        self.mock_isdir = self.mock_isdir_patch.start()
        self.mock_makedirs = self.mock_makedirs_patch.start()
        self.mock_sys_call = self.mock_sys_call_patch.start()
        self.mock_chdir = self.mock_chdir_patch.start()
        self.mock_getcwd = self.mock_getcwd_patch.start()
        #define specific mock attributes/behaviors
        self.mock_isdir.side_effect = lambda x : x in self.dirList
        self.mock_makedirs.side_effect = lambda x : self.dirList.append(x)
        def mock_chdir(x):
            if x in self.dirList:
                self.CWD = x
            else:
                raise OSError
        self.mock_chdir.side_effect = mock_chdir
        self.mock_getcwd.return_value = self.CWD

    def tearDown(self):
        self.mock_isdir_patch.stop()
        self.mock_makedirs_patch.stop()
        self.mock_sys_call_patch.stop()
        self.mock_chdir_patch.stop()
        self.mock_getcwd_patch.stop()
        self.dirList = [self.ROOTDIR]

    def resetDirectories(self):
        self.ROOTDIR = "/HOME"
        self.dirList = [self.ROOTDIR]


class GeneralFunctionsTest(GeneralFunctionsMocks):
    # TODO set file permisions
    def test_directory_exists(self):
        self.assertTrue(nwb.CheckDirectory(self.ROOTDIR))

    def test_directory_created(self):
        self.assertFalse(nwb.CheckDirectory(self.ROOTDIR+"/test"))
        self.assertTrue(nwb.CheckDirectory(self.ROOTDIR+"/test", True))
        self.assertTrue(nwb.CheckDirectory(self.ROOTDIR+"/test"))

    def test_find_url(self):
        self.assertTrue(nwb.url_ok("https://github.com/spack/spack.git"))

    def test_clone_repo_url_exists(self):
        repoUrl = "https://github.com/spack/spack.git"
        repoDir = self.ROOTDIR+"/spack"
        nwb.CloneRepo(repoUrl,repoDir)
        self.mock_sys_call.assert_called_once_with("git clone --recursive"
            " {url} {rdir}".format(url=repoUrl, rdir=repoDir))

    def test_clone_repo_url_bad(self):
        repoUrl = "https://gothib.com/spock/spock.git"
        repoDir = self.ROOTDIR+"/spack"
        with self.assertRaises(urllib2.URLError):
            nwb.CloneRepo(repoUrl,repoDir)

    def test_update_repo(self):
        self.resetDirectories()
        repoUrl = "https://github.com/spack/spack.git"
        repoDir = self.ROOTDIR+"/spack"
        nwb.CloneRepo(repoUrl, repoDir)
        nwb.UpdateRepo(repoDir,"origin", "develop")
        self.mock_sys_call.assert_any_call(
                "git fetch origin develop")
        self.mock_sys_call.assert_called_with(
                "git pull --rebase origin develop")
        self.assertEqual(self.ROOTDIR, nwb.os.getcwd())

class ReadInputMock(unittest.TestCase):
    # TODO rootdir absolute/env vars/etc?
    # TODO set file permisions
    def test_read_params_with_no_flags_or_variants(self):
        inputFile = """
            machine: mac
            os: darwin
            rootdir: /blah/blah2
            """
        with mock.patch('naluWindBuild.open', mock.mock_open(read_data=inputFile)):
            params = nwb.ReadInputParams("dummy.txt")
        self.assertEqual("darwin",params["os"])
        self.assertEqual("mac",params["machine"])
        self.assertEqual("/blah/blah2", params["rootdir"])
        self.assertEqual("", params["flags"])
        self.assertEqual("", params["variants"])

    def test_read_params_with_no_variants(self):
        inputFile = """
            machine: mac
            os: darwin
            rootdir: /blah/blah2
            flags: --only dependencies --dirty
            """
        with mock.patch('naluWindBuild.open', mock.mock_open(read_data=inputFile)):
            params = nwb.ReadInputParams("dummy.txt")
        self.assertEqual("darwin",params["os"])
        self.assertEqual("mac",params["machine"])
        self.assertEqual("/blah/blah2", params["rootdir"])
        self.assertEqual("--only dependencies --dirty", params["flags"])
        self.assertEqual("", params["variants"])

    def test_read_params(self):
        inputFile = """
            machine: mac
            os: darwin
            rootdir: /blah/blah2
            flags: --dirty
            variants: +openfast ~shared
            """
        with mock.patch('naluWindBuild.open', mock.mock_open(read_data=inputFile)):
            params = nwb.ReadInputParams("dummy.txt")
        self.assertEqual("darwin",params["os"])
        self.assertEqual("mac",params["machine"])
        self.assertEqual("/blah/blah2", params["rootdir"])
        self.assertEqual("--dirty", params["flags"])
        self.assertEqual("+openfast ~shared", params["variants"])

if __name__ == "__main__":
    unittest.main()
