package zip

import "core:encoding/endian"
import "core:io"
import "core:strings"

get_eocd_offset :: proc(z: ^ZipFile) -> (offset: i64, err: Error) {
    buf := make([]byte, 4)

    offset = z.size - 4

    for {
        _ = io.read_at(z.__stream, buf, offset) or_return
        if signature, _ := endian.get_u32(buf[:], .Little); signature == 0x504b0506 {
            break
        }
        offset -= 1
    }

    return
}

read_eocd :: proc(z: ^ZipFile, offset: i64) -> (header: EndOfCentralDirectory, err: Error) {
    eocd_size := z.size - offset
    buf := make([]byte, eocd_size)
    defer delete(buf)

    n := io.read_at(z.__stream, buf, offset) or_return
    if n < len(buf) {
        err = ZipError.EOCDReadErr
        return
    }

    header.signature, _ = endian.get_u32(buf[0:4], .Little)
    if header.signature != 0x504b0506 {
        err = ZipError.InvalidEOCDSignature
        return
    }

    header.disk_number, _ = endian.get_u16(buf[4:6], .Little)
    header.central_dir_start_disk, _ = endian.get_u16(buf[6:8], .Little)
    header.central_dir_disk_records, _ = endian.get_u16(buf[8:10], .Little)
    header.central_dir_total_records, _ = endian.get_u16(buf[10:12], .Little)
    header.central_dir_size, _ = endian.get_u32(buf[12:16], .Little)
    header.central_dir_offset, _ = endian.get_u32(buf[16:20], .Little)
    header.comment_len, _ = endian.get_u16(buf[20:22], .Little)
    header.comment = strings.clone_from(buf[22:]) or_return

    return
}

read_central_dir :: proc(z: ^ZipFile, offset: i64, size: int) -> (record: CentralDirectory, err: Error) {
    buf := make([]byte, size)
    defer delete(buf)

    num := io.read_at(z.__stream, buf, offset) or_return
    if num < len(buf) {
        err = ZipError.CDReadErr
        return
    }

    record.signature, _ = endian.get_u32(buf[:4], .Little)
    if record.signature != 0x504b0102 {
        err = ZipError.InvalidCDSignature
        return
    }

    record.created_version, _ = endian.get_u16(buf[4:6], .Little)
    record.minimum_version, _ = endian.get_u16(buf[6:8], .Little)
    record.bit_flag, _ = endian.get_u16(buf[8:10], .Little)

    c, _ := endian.get_u16(buf[10:12], .Little)
    switch c {
    case 0:
        record.compression_method = .None
    case 8:
        record.compression_method = .Deflate
    case:
        err = ZipError.UnsupportedCompressionMethod
        return
    }

    record.last_modified_time, _ = endian.get_u16(buf[12:14], .Little)
    record.last_modified_date, _ = endian.get_u16(buf[14:16], .Little)
    record.checksum, _ = endian.get_u32(buf[16:20], .Little)
    record.compressed_size, _ = endian.get_u32(buf[20:24], .Little)
    record.uncompressed_size, _ = endian.get_u32(buf[24:28], .Little)
    n, _ := endian.get_u16(buf[28:30], .Little)
    record.file_name_len = n
    m, _ := endian.get_u16(buf[30:32], .Little)
    record.extra_field_len = m
    k, _ := endian.get_u16(buf[32:34], .Little)
    record.comment_len = k
    record.start_disk, _ = endian.get_u16(buf[34:36], .Little)
    record.internal_file_attr, _ = endian.get_u16(buf[36:38], .Little)
    record.external_file_attr, _ = endian.get_u32(buf[38:42], .Little)
    record.offset_to_file_header, _ = endian.get_u32(buf[42:46], .Little)
    record.file_name = strings.clone_from(buf[46:46 + n]) or_return
    record.extra_field = read_extra_field(buf[46 + n:46 + m])
    record.comment = strings.clone_from(buf[46 + n + m:]) or_return

    return
}

read_extra_field :: proc(data: []byte) -> (field: ExtraField) {
    field.header, _ = endian.get_u16(data[:2], .Little)
    field.len, _ = endian.get_u16(data[2:4], .Little)
    field.data = data[4:]
    return
}
