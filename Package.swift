import PackageDescription


var urls = [
	"https://github.com/PerfectlySoft/Perfect-Thread.git", 
	"https://github.com/PerfectlySoft/Perfect-MySQL.git"
]

let package = Package(
	name: "MySQLConnectionPool",
	targets: [],
	dependencies: urls.map { .Package(url: $0, majorVersion: 2, minor: 0) },
	exclude: []
)


