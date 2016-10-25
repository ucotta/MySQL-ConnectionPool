import PackageDescription


var urls = ["https://github.com/PerfectlySoft/Perfect-Thread.git"]

#if os(OSX)
urls.append("https://github.com/PerfectlySoft/Perfect-mysqlclient.git")
#else
urls.append("https://github.com/PerfectlySoft/Perfect-mysqlclient-Linux.git")
#endif


let package = Package(
	name: "PerfectMySQLConnectionPool",
	targets: [],
	dependencies: urls.map { .Package(url: $0, majorVersion: 2, minor: 0) },
	exclude: []
)


