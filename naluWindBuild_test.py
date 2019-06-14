import unittest
import mock
import naluWindBuild as nwb

class GeneralFunctionsTest(unittest.TestCase):
    def setUp(self):
        self.ROOTDIR = "/HOME"
        self.dirList = [self.ROOTDIR]
        self.mock_isdir_patch = mock.patch("naluWindBuild.os.path.isdir")
        self.mock_isdir = self.mock_isdir_patch.start()
        self.mock_isdir.side_effect = lambda x : x in self.dirList
        self.mock_makedirs_patch = mock.patch("naluWindBuild.os.makedirs")
        self.mock_makedirs = self.mock_makedirs_patch.start()
        self.mock_makedirs.side_effect = lambda x : self.dirList.append(x)
        self.mock_os_system_patch = mock.patch("naluWindBuild.os.system")
        self.mock_os_system = self.mock_os_system_patch.start()

    def tearDown(self):
        self.mock_isdir_patch.stop()
        self.mock_makedirs_patch.stop()
        self.mock_os_system_patch.stop()

    def test_directory_exists(self):
        #with self.mock_isdir as mock_isdir:
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
        self.mock_os_system.assert_called_once_with("git clone --recursive"
            " {url} {rdir}".format(url=repoUrl, rdir=repoDir))

if __name__ == "__main__":
    unittest.main()
