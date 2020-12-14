using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;
using System.ComponentModel;

namespace KerberosLib
{
    internal struct LUID
    {
        public int LowPart;
        public int HighPart;
    }

    [StructLayout(LayoutKind.Explicit, Size = 8)]
    internal struct LARGE_INTEGER
    {
        [FieldOffset(0)]
        public Int64 QuadPart;
        [FieldOffset(0)]
        public UInt32 LowPart;
        [FieldOffset(4)]
        public Int32 HighPart;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct KERB_QUERY_TKT_CACHE_REQUEST
    {
        public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
        public LUID LogonId;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct KERB_PURGE_TKT_CACHE_REQUEST
    {
        public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
        public LUID LogonId;
        public UNICODE_STRING_x86 ServerName;
        public UNICODE_STRING_x86 RealmName;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct KERB_QUERY_TKT_CACHE_RESPONSE
    {
        public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
        public int CountOfTickets;
        public IntPtr Tickets;
    }

    [StructLayout(LayoutKind.Explicit, Size = 64, CharSet = CharSet.Unicode)]
    internal struct KERB_TICKET_CACHE_INFO_x64
    {
        [FieldOffset(0)]
        public UNICODE_STRING_x64 ServerName;
        [FieldOffset(16)]
        public UNICODE_STRING_x64 RealmName;
        [FieldOffset(32)]
        public long StartTime;
        [FieldOffset(40)]
        public long EndTime;
        [FieldOffset(48)]
        public long RenewTime;
        [FieldOffset(56)]
        public uint EncryptionType;
        [FieldOffset(60)]
        public uint TicketFlags;
    }

    [StructLayout(LayoutKind.Explicit, Size = 16, CharSet = CharSet.Unicode)]
    internal struct UNICODE_STRING_x64
    {
        [FieldOffset(0)]
        public ushort Length;
        [FieldOffset(2)]
        public ushort MaximumLength;
        [FieldOffset(8)]
        public IntPtr Buffer;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    internal struct KERB_TICKET_CACHE_INFO_x86
    {
        public UNICODE_STRING_x86 ServerName;
        public UNICODE_STRING_x86 RealmName;
        public long StartTime;
        public long EndTime;
        public long RenewTime;
        public uint EncryptionType;
        public uint TicketFlags;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    internal struct UNICODE_STRING_x86
    {
        public ushort Length;
        public ushort MaximumLength;
        public IntPtr Buffer;
    }

}