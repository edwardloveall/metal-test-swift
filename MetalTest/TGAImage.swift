import Foundation
import simd

class TGAImage {
  let width: Int
  let height: Int
  let data: Data
  let header: TGAHeader

  struct TGAHeader {
    let idSize: uint8
    let colorMapType: uint8
    let imageType: uint8
    let colorMapBpp: uint8
    let colorMapStart: uint16
    let colorMapLength: uint16
    let xOffset: uint16
    let yOffset: uint16
    let width: uint16
    let height: uint16
    let bitsPerPixel: uint8
    let descriptor: uint8

    init(data: Data) {
      let extractor = Extractor(data: data)
      idSize = extractor.nextValue()
      colorMapType = extractor.nextValue()
      imageType = extractor.nextValue()
      colorMapStart = extractor.nextValue()
      colorMapLength = extractor.nextValue()
      colorMapBpp = extractor.nextValue()
      xOffset = extractor.nextValue()
      yOffset = extractor.nextValue()
      width = extractor.nextValue()
      height = extractor.nextValue()
      bitsPerPixel = extractor.nextValue()
      descriptor = extractor.nextValue()
    }
  }

  init?(location: URL) {
    if location.pathExtension.lowercased() != "tga" {
      fatalError("TGAImage only supports the loading of TGA files")
    }
    var fileData = Data()
    do {
      fileData = try Data(contentsOf: location)
    } catch {
      fatalError("Could not open TGA File")
    }

    self.header = TGAHeader(data: fileData)
    self.width = Int(header.width)
    self.height = Int(header.height)
    self.data = fileData

    guard header.imageType == 2 else {
      fatalError("TGAImage only supports non-compressed BGR(A) TGA files")
    }

    guard header.colorMapType == 0 else {
      fatalError("TGAImage doesn't support TGA files with a colormap")
    }

    guard header.xOffset == 0, header.yOffset == 0 else {
      fatalError("TGAImage doesn't support TGA files with offsets")
    }

    guard header.bitsPerPixel == 32 || header.bitsPerPixel == 24 else {
      fatalError("TGAImage only supports 24-bit and 32-bit TGA files")
    }

    if header.bitsPerPixel == 32 {
      guard header.descriptor & 0xf != 8 else {
        fatalError("TGAImage only supports 32-bit TGA files with 8 bits of alpha")
      }
    } else if header.descriptor != 0 {
      fatalError("TGAImage only supports the default descriptor")
    }
  }

  func normalizedData() -> [UInt8] {
    let newPixelSize = MemoryLayout<UInt32>.size
    let oldPixelSize = newPixelSize - MemoryLayout<UInt8>.size
    let pixelDataOffset = MemoryLayout<TGAHeader>.size + Int(header.idSize)
    let pixelDataLength = width * height * newPixelSize
    var onlyPixelData = Array<UInt8>(repeating: 0, count: pixelDataLength)

    if header.bitsPerPixel == 24 {
      for y in (0..<height) {
        for x in (0..<width) {
          let newDataIndex = newPixelSize * (y * width + x)
          let oldDataIndex = oldPixelSize * (y * width + x) + pixelDataOffset

          onlyPixelData[newDataIndex] = data[oldDataIndex]
          onlyPixelData[newDataIndex + 1] = data[oldDataIndex + 1]
          onlyPixelData[newDataIndex + 2] = data[oldDataIndex + 2]
          onlyPixelData[newDataIndex + 3] = 255
        }
      }
    } else {
      onlyPixelData = data.withUnsafeBytes {
        [UInt8](UnsafeBufferPointer(start: $0, count: data.count))
      }
    }

    return onlyPixelData
  }
}

class Extractor {
  var cursor: Int = 0
  let data: Data

  init(data: Data) {
    self.data = data
  }

  func nextValue<T>() -> T {
    let length = MemoryLayout<T>.size
    let endCursor = cursor + length
    let value: T = data[cursor..<endCursor].withUnsafeBytes { $0.pointee }
    cursor = endCursor
    return value
  }
}
