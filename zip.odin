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

main :: proc() {
    zip, open_err := open("test.zip")
    if open_err != nil {
        fmt.eprintln("Failed to open zip file:", open_err)
    }


    // eocd, eocd_err := get_eocd(zip)
    // if eocd_err != nil {
    //     fmt.eprintln("Failed to get EOCD:", eocd_err)
    // }
    //
    // first, err := get_central_directory(zip, eocd.cdSize, eocd.cdOffset)
    // if err != nil {
    //     fmt.eprintln("Failed to get first central directory:", err)
    // }
    //
    // fmt.printf("%#v\n", first)
}
