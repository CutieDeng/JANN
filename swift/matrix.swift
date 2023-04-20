import MetalPerformanceShaders 

@_cdecl("swift:float32:matrix multiplication")
// pass a float pointer 
public func matrixMultiplication32(a: UnsafePointer<Float32>, b: UnsafePointer<Float32>, c: UnsafePointer<Float32>, resultRow: Int, resultColumn: Int, internals: Int) {
    // gpu device 
    let device = MTLCreateSystemDefaultDevice()! 
    // command queue 
    let commandQueue = device.makeCommandQueue()! 
    // command buffer 
    let commandBuffer = commandQueue.makeCommandBuffer()! 
    // Matrix a, b, c: 
    // let aMatrix = device.makeBuffer(bytes: a, length: MemoryLayout<Float32>.size * resultRow * internals, options: [])! 
    let aRaw = UnsafeMutableRawPointer(mutating: a) 
    // let aMatrix = device.makeBuffer(bytesNoCopy: aRaw, length: Int(MemoryLayout<Float32>.size * resultRow * internals), options: [], deallocator: nil)! 
    let aMatrix = device.makeBuffer(bytes: aRaw, length: Int(MemoryLayout<Float32>.size * resultRow * internals))! 
    let bRaw = UnsafeMutableRawPointer(mutating: b) 
    // let bMatrix = device.makeBuffer(bytesNoCopy: bRaw, length: Int(MemoryLayout<Float32>.size * internals * resultColumn), options: [], deallocator: nil)! 
    let bMatrix = device.makeBuffer(bytes: bRaw, length: Int(MemoryLayout<Float32>.size * internals * resultColumn))!
    let cRaw = UnsafeMutableRawPointer(mutating: c) 
    // let cMatrix = device.makeBuffer(bytesNoCopy: cRaw, length: Int(MemoryLayout<Float32>.size * resultRow * resultColumn), options: [], deallocator: nil)! 
    let cMatrix = device.makeBuffer(bytes: cRaw, length: Int(MemoryLayout<Float32>.size * resultRow * resultColumn))!
    // matrix descriptor  
    let aDescriptor = MPSMatrixDescriptor(rows: resultRow, columns: internals, rowBytes: MemoryLayout<Float32>.size * internals, dataType: .float32) 
    let bDescriptor = MPSMatrixDescriptor(rows: internals, columns: resultColumn, rowBytes: MemoryLayout<Float32>.size * resultColumn, dataType: .float32) 
    let cDescriptor = MPSMatrixDescriptor(rows: resultRow, columns: resultColumn, rowBytes: MemoryLayout<Float32>.size * resultColumn, dataType: .float32) 
    // matrix a, b, c 
    let aMatrixObject = MPSMatrix(buffer: aMatrix, descriptor: aDescriptor) 
    let bMatrixObject = MPSMatrix(buffer: bMatrix, descriptor: bDescriptor) 
    let cMatrixObject = MPSMatrix(buffer: cMatrix, descriptor: cDescriptor) 
    // matrix multiply 
    let matrixMultiply = MPSMatrixMultiplication(device: device, transposeLeft: false, transposeRight: false, resultRows: resultRow, resultColumns: resultColumn, interiorColumns: internals, alpha: 1.0, beta: 0.0) 
    // encode 
    matrixMultiply.encode(commandBuffer: commandBuffer, leftMatrix: aMatrixObject, rightMatrix: bMatrixObject, resultMatrix: cMatrixObject) 
    // commit 
    commandBuffer.commit() 
    commandBuffer.waitUntilCompleted() 
    // set the contents of c 
    let cRawPointer = cMatrix.contents() 
    let cPointer = cRawPointer.bindMemory(to: Float32.self, capacity: resultRow * resultColumn) 
    let cWriter = UnsafeMutablePointer<Float32>(mutating: c) 
    for i in 0..<resultRow * resultColumn {
        cWriter[i] = cPointer[i] 
    } 
}