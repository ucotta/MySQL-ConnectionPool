import PackageDescription

#if os(OSX)
let package = Package(
    name: "PerfectMySQLConnectionPool"
    targets: [],
    dependencies: [
		.Package(url: "https://github.com/PerfectlySoft/Perfect-mysqlclient.git", majorVersion: 2, minor: 0)
    ],
    exclude: []
)
#else
let package = Package(
    name: "PerfectMySQLConnectionPool"
    targets: [],
    dependencies: [
		.Package(url: "https://github.com/PerfectlySoft/Perfect-mysqlclient-Linux.git", majorVersion: 2, minor: 0)
    ],
    exclude: []
)
#endif
