package oserr

import "core:os"

// enum wrapper for os.Errno
OsError :: enum {
	None               = 0,
	AccessDenied       = 5,
	AlreadyExists      = 183,
	BrokenPipe         = 109,
	BufferOverflow     = 111,
	DirNotEmpty        = 145,
	EnvVarNotFound     = 203,
	EOF                = 38,
	FileExists         = 80,
	FileIsNotDir       = 1 << 29 + 1,
	FileIsPipe         = 1 << 29 + 0,
	FileNotFound       = 2,
	HandleEOF          = 38,
	InsufficientBuffer = 122,
	InvalidHandle      = 6,
	InvalidParameter   = 87,
	IoPending          = 997,
	ModNotFound        = 126,
	MoreData           = 234,
	NegativeOffset     = 1 << 29 + 2,
	NetnameDeleted     = 64,
	NotEnoughMemory    = 8,
	NotFound           = 1168,
	NoMoreFiles        = 18,
	OperationAborted   = 995,
	PathNotFound       = 3,
	PrivilegeNotHeld   = 1314,
	ProcNotFound       = 127,
}

// translates an os.Errno into an OsErr
from_errno :: proc(errno: os.Errno) -> OsError {
	return OsError(errno)
}
