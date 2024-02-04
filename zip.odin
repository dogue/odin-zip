package zip

import "core:bufio"
import "core:c/libc"
import "core:encoding/endian"
import "core:fmt"
import "core:io"
import "core:os"
import "core:slice"
import "core:strings"
import "oserr"

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
            header.comment = strings.clone_from(buf[start:end]) or_return
        }
        i -= 1
    }

    if header.signature != 0x06054b50 {
        err = ZipError.NoEOCDFound
    }
    return
}

get_central_directory :: proc(z: ^ZipFile, size: u32, offset: u32) -> (header: CentralDirectory, err: Error) {
    buf := make([]byte, size)
    defer delete(buf)

    io.seek(z.__stream, i64(offset), .Start) or_return
    io.read_full(z.__stream, buf) or_return

    start := 0
    end := 4
    header.signature, _ = endian.get_u32(buf[start:end], .Little)

    start = end
    end = start + 2
    header.createdVersion, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 2
    header.minVersion, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 2
    header.bitFlag, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 2
    method, _ := endian.get_u16(buf[start:end], .Little)
    if method == 0x0008 {
        header.compressionMethod = .Deflate
    }

    start = end
    end = start + 2
    header.lastModTime, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 2
    header.lastModDate, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 4
    header.checksum, _ = endian.get_u32(buf[start:end], .Little)

    start = end
    end = start + 4
    header.compressedSize, _ = endian.get_u32(buf[start:end], .Little)

    start = end
    end = start + 4
    header.uncompressedSize, _ = endian.get_u32(buf[start:end], .Little)

    start = end
    end = start + 2
    header.fileNameLen, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 2
    header.extraFieldLen, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 2
    header.commentLen, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 2
    header.startDisk, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 2
    header.internalAttr, _ = endian.get_u16(buf[start:end], .Little)

    start = end
    end = start + 4
    header.externalAttr, _ = endian.get_u32(buf[start:end], .Little)

    start = end
    end = start + 4
    header.offsetToLFH, _ = endian.get_u32(buf[start:end], .Little)

    start = end
    end = start + int(header.fileNameLen)
    header.fileName = strings.clone_from(buf[start:end]) or_return

    start = end
    end = start + int(header.extraFieldLen)
    header.extraField = slice.clone(buf[start:end]) or_return

    start = end
    end = start + int(header.commentLen)
    header.comment = strings.clone_from(buf[start:end]) or_return

    return
}

main :: proc() {
    zip, open_err := open("test.zip")
    if open_err != nil {
        fmt.eprintln("Failed to open zip file:", open_err)
    }

    eocd, eocd_err := get_eocd(zip)
    if eocd_err != nil {
        fmt.eprintln("Failed to get EOCD:", eocd_err)
    }

    first, err := get_central_directory(zip, eocd.cdSize, eocd.cdOffset)
    if err != nil {
        fmt.eprintln("Failed to get first central directory:", err)
    }

    fmt.printf("%#v\n", first)
}
