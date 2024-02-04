package zip

import "core:io"
import "core:mem"
import "oserr"

ZipError :: enum {
    None,
    NoEOCDFound,
}

Error :: union #shared_nil {
    ZipError,
    oserr.OsError,
    io.Error,
    mem.Allocator_Error,
}
