// swift-tools-version:5.5
import PackageDescription


let package = Package(
    name: "TouchXML",
    products: [.library(name: "TouchXML", targets: ["TouchXML"])],
    targets: [
        .target(
            name: "TouchXML", path: "Source",
            publicHeadersPath: "z-include", cSettings: [.headerSearchPath("z-include"), .headerSearchPath("z-include-private")],
            linkerSettings: [.linkedLibrary("xml2")]
        )
    ]
)
