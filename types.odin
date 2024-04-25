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

CompressionMethod :: enum (u16) {
    None    = 0,
    Deflate = 8,
}

LocalFile :: struct {
    signature:          u32,
    minimum_version:    u16,
    bit_flag:           u16,
    compression_method: CompressionMethod,
    last_modified_time: u16,
    last_modified_date: u16,
    checksum:           u32,
    compressed_size:    u32,
    uncompressed_size:  u32,
    file_name_len:      u16,
    extra_field_len:    u16,
    file_name:          string,
    extra_field:        ExtraField,
}

CentralDirectory :: struct {
    signature:             u32,
    created_version:       u16,
    minimum_version:       u16,
    bit_flag:              u16,
    compression_method:    CompressionMethod,
    last_modified_time:    u16,
    last_modified_date:    u16,
    checksum:              u32,
    compressed_size:       u32,
    uncompressed_size:     u32,
    file_name_len:         u16,
    extra_field_len:       u16,
    comment_len:           u16,
    start_disk:            u16,
    internal_file_attr:    u16,
    external_file_attr:    u32,
    offset_to_file_header: u32,
    file_name:             string,
    extra_field:           ExtraField,
    comment:               string,
}

EndOfCentralDirectory :: struct {
    signature:                 u32,
    disk_number:               u16,
    central_dir_start_disk:    u16,
    central_dir_disk_records:  u16,
    central_dir_total_records: u16,
    central_dir_size:          u32,
    central_dir_offset:        u32,
    comment_len:               u16,
    comment:                   string,
}

ExtraField :: struct {
    header: u16,
    len:    u16,
    data:   []byte,
}
