// Copies TDL's Window.tga to PNG without its fixed divider (rows 728-749 at 1024px),
// so the stretched side borders stay clean above a composer that changes height.
// Usage: swift frame.swift <Window.tga> <out.png>
import Cocoa

let args = CommandLine.arguments
guard args.count == 3, let data = FileManager.default.contents(atPath: args[1]),
      let img = NSBitmapImageRep(data: data), img.pixelsHigh == 1024 else {
    FileHandle.standardError.write("frame.swift: expected a 1024px Window.tga\n".data(using: .utf8)!)
    exit(1)
}
for y in 728...749 {
    for x in 0..<img.pixelsWide {
        img.setColor(img.colorAt(x: x, y: y - 28)!, atX: x, y: y)
    }
}
try img.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
