import naluWindBuild_test as NWBT
import sys
import unittest
try:
    import mock
except:
    import unittest.mock as mock

class MockInstallFromInput(NWBT.GeneralFunctionsMocks):
    def test_execution(self):
        params = NWBT.nwb.ReadInputParams(configFile)
        self.resetDirectories(params["rootdir"])
        self.assertTrue(NWBT.nwb.os.path.isdir(params["rootdir"]))
        NWBT.nwb.BuildNaluWindSpack(configFile) 

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please pass a configuration file.")
        exit(1)
    else:
        configFile = sys.argv[1]
    del sys.argv[1]
    unittest.main()
