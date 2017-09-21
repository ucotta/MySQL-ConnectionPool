import PackageDescription


let package = Package(
	name: "MySQLConnectionPool",
	targets: [],
	dependencies: [
        	.Package(url: "https://github.com/PerfectlySoft/Perfect-Thread.git", majorVersion: 3),
         	.Package(url: "https://github.com/PerfectlySoft/Perfect-MySQL.git", majorVersion: 3),
	],
	exclude: []
)


