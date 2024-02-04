package zip

import "core:io"

ZipFile :: struct {
    __stream: io.Stream,
    size:     i64,
}

Header :: union {
    LocalFile,
    CentralDirectory,
    EndOfCentralDirectory,
}

CompressionMethod :: enum {
    None,
    Deflate,
}

LocalFile :: struct {
    signature:         u32,
    minVersion:        u16,
    bitFlag:           u16,
    compressionMethod: CompressionMethod,
    lastModTime:       u16,
    lastModDate:       u16,
    checksum:          u32,
    compressedSize:    u32,
    uncompressedSize:  u32,
    fileNameLen:       u16,
    extraFieldLen:     u16,
    fileName:          string,
    extraField:        []byte,
}

CentralDirectory :: struct {
    signature:         u32,
    createdVersion:    u16,
    minVersion:        u16,
    bitFlag:           u16,
    compressionMethod: CompressionMethod,
    lastModTime:       u16,
    lastModDate:       u16,
    checksum:          u32,
    compressedSize:    u32,
    uncompressedSize:  u32,
    fileNameLen:       u16,
    extraFieldLen:     u16,
    commentLen:        u16,
    startDisk:         u16,
    internalAttr:      u16,
    externalAttr:      u32,
    offsetToLFH:       u32,
    fileName:          string,
    extraField:        []byte,
    comment:           string,
}

EndOfCentralDirectory :: struct {
    signature:    u32,
    diskNumber:   u16,
    cdDisk:       u16,
    cdDiskCount:  u16,
    cdTotalCount: u16,
    cdSize:       u32,
    cdOffset:     u32,
    commentLen:   u16,
    comment:      string,
}
