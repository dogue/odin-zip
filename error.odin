package zip

import "core:io"
import "core:mem"
import "oserr"

ZipError :: enum {
    None,
    NoEOCDFound,
    EOCDReadErr,
    CDReadErr,
    InvalidEOCDSignature,
    InvalidCDSignature,
    InvalidLFGSignature,
    UnsupportedCompressionMethod,
}

Error :: union #shared_nil {
    ZipError,
    oserr.OsError,
    io.Error,
    mem.Allocator_Error,
}
