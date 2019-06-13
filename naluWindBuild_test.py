import unittest
import mock
import naluWindBuild as nwb

class GeneralFunctionsTest(unittest.TestCase):
    @mock.patch('naluWindBuild.os.path.isdir')
    def test_directory_exists(self, mock_isdir):
        mock_isdir.return_value = True
        self.assertTrue(nwb.CheckDirectory("/asdjflasd/asdkjfla"))

    def test_directory_doesnt_exist(self):
        mock_isdir = mock.patch('naluWindBuild.os.path.isdir')
        mock_isdir.return_value = False
        self.assertFalse(nwb.CheckDirectory("/asdjflasd/asdkjfla"))


if __name__ == "__main__":
    unittest.main()
