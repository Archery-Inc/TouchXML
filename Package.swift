// swift-tools-version:5.5
import PackageDescription


let package = Package(
    name: "TouchXML",
    products: [.library(name: "TouchXML", targets: ["TouchXML"])],
    targets: [
        .target(
            name: "TouchXML", path: "Source",
            publicHeadersPath: "include", cSettings: [.headerSearchPath("include"), .headerSearchPath("PrivateHeaders")],
            linkerSettings: [.linkedLibrary("xml2")],
        )
    ]
)
