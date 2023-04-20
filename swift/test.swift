import MetalPerformanceShaders 

let device = MTLCreateSystemDefaultDevice()! 
let commandQueue = device.makeCommandQueue()! 
let commandBuffer = commandQueue.makeCommandBuffer()! 

let matrixAEntities : [Float32] = [
    2, 7,
    1, 8,
    2, 8
]

let matrixBEntities : [Float32] = [
    3, 1, 4, 
    1, 5, 9
]

let mmKernel = MPSMatrixMultiplication(
    device: device, resultRows: 3, resultColumns: 3, interiorColumns: 2 
)

let bufferA = device.makeBuffer(bytes: matrixAEntities, length: matrixAEntities.count * MemoryLayout<Float32>.stride, options: .storageModeShared) 
let A = MPSMatrix(buffer: bufferA!, descriptor: MPSMatrixDescriptor(rows: 3, columns: 2, rowBytes: 2 * MemoryLayout<Float32>.stride, dataType: .float32)) 

let bufferB = device.makeBuffer(bytes: matrixBEntities, length: matrixBEntities.count * MemoryLayout<Float32>.stride, options: .storageModeShared) 
let B = MPSMatrix(buffer: bufferB!, descriptor: MPSMatrixDescriptor(rows: 2, columns: 3, rowBytes: 3 * MemoryLayout<Float32>.stride, dataType: .float32)) 

let bufferC = device.makeBuffer(length: 9 * MemoryLayout<Float32>.stride, options: .storageModeShared) 
let C = MPSMatrix(buffer: bufferC!, descriptor: MPSMatrixDescriptor(rows: 3, columns:3, rowBytes: 3 * MemoryLayout<Float32>.stride, dataType: .float32)) 

mmKernel.encode(commandBuffer: commandBuffer, leftMatrix: A, rightMatrix: B, resultMatrix: C) 
commandBuffer.commit() 
commandBuffer.waitUntilCompleted() 

var output : [Float32] = [] 

let rawPointer = C.data.contents() 
let typePointer = rawPointer.bindMemory(to: Float32.self, capacity: A.rows * B.columns)  
let bufferPointer = UnsafeBufferPointer(start: typePointer, count: A.rows * B.columns)
_ = bufferPointer.map {
    value in 
    output += [value] 
}

for i in 0..<output.count {
    if i % 3 == 2 {
        print(output[i]) 
    } else {
        print(output[i], terminator: " ") 
    } 
}