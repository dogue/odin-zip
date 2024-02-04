package zip

import "core:bufio"
import "core:c/libc"
import "core:encoding/endian"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "oserr"

ZipFile :: struct {
    __stream: io.Stream,
    size:     i64,
}

Header :: union {
    LocalFile,
    CentralDirectory,
    EndOfCentralDirectory,
}

LocalFile :: struct {
    signature:         u32,
    minVersion:        u16,
    bitFlag:           u16,
    compressionMethod: u16,
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
    compressionMethod: u16,
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

open :: proc {
    open_from_file,
    open_from_handle,
}

open_from_file :: proc(path: string) -> (zip: ^ZipFile, err: Error) {
    file, o_err := os.open(path, os.O_RDONLY)
    if o_err != os.ERROR_NONE {
        err = oserr.from_errno(o_err)
        return
    }

    return open_from_handle(&file)
}

open_from_handle :: proc(file: ^os.Handle) -> (zip: ^ZipFile, err: Error) {
    fileStream := os.stream_from_handle(file^)
    zip = new(ZipFile) or_return
    zip.__stream = fileStream
    zip.size, err = io.size(zip.__stream)
    return
}

get_eocd :: proc(z: ^ZipFile) -> (header: EndOfCentralDirectory, err: Error) {
    bufSize: int
    if z.size > 0xffff {
        bufSize = 0xffff
    } else {
        bufSize = int(z.size)
    }

    buf := make([]byte, bufSize)
    defer delete(buf)

    io.read_full(z.__stream, buf) or_return

    i := len(buf) - 4
    for i > 0 {
        if buf[i] == 0x50 && buf[i + 1] == 0x4b && buf[i + 2] == 0x05 && buf[i + 3] == 0x06 {
            start := i
            end := start + 4
            header.signature, _ = endian.get_u32(buf[start:end], .Little)

            start = end
            end = start + 2
            header.diskNumber, _ = endian.get_u16(buf[start:end], .Little)

            start = end
            end = start + 2
            header.cdDisk, _ = endian.get_u16(buf[start:end], .Little)

            start = end
            end = start + 2
            header.cdDiskCount, _ = endian.get_u16(buf[start:end], .Little)

            start = end
            end = start + 2
            header.cdTotalCount, _ = endian.get_u16(buf[start:end], .Little)

            start = end
            end = start + 4
            header.cdSize, _ = endian.get_u32(buf[start:end], .Little)

            start = end
            end = start + 4
            header.cdOffset, _ = endian.get_u32(buf[start:end], .Little)

            start = end
            end = start + 2
            header.commentLen, _ = endian.get_u16(buf[start:end], .Little)

            start = end
            end = start + int(header.commentLen)
            commentBytes := buf[start:end]
            header.comment = strings.clone_from_bytes(commentBytes) or_return
        }
        i -= 1
    }

    if header.signature != 0x06054b50 {
        err = ZipError.NoEOCDFound
    }

    return
}

main :: proc() {
    zip, open_err := open("test.zip")
    if open_err != nil {
        fmt.eprintln("Failed to open zip file:", open_err)
    }

    eocd, err := get_eocd(zip)
    if err != nil {
        fmt.eprintln("Failed to get EOCD:", err)
    }

    fmt.printf("%#v\n", eocd)
}
