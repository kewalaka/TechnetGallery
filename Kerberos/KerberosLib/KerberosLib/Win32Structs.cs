using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;
using System.ComponentModel;

namespace KerberosLib
{
    #region UnicodeString
    [StructLayout(LayoutKind.Sequential)]
    internal struct UnicodeString : IDisposable
    {
        public UnicodeString(string str)
        {
            if (str != null)
            {
                UnicodeString newString;

                if (!Win32.RtlCreateUnicodeString(out newString, str))
                    throw new OutOfMemoryException();

                this = newString;
            }
            else
            {
                this.Length = 0;
                this.MaximumLength = 0;
                this.Buffer = IntPtr.Zero;
            }
        }

        public ushort Length;
        public ushort MaximumLength;
        public IntPtr Buffer;

        public void Dispose()
        {
            if (this.Buffer == IntPtr.Zero)
                return;

            Win32.RtlFreeUnicodeString(ref this);
            this.Buffer = IntPtr.Zero;
        }

        public string Read()
        {
            if (this.Length == 0)
                return "";

            return Marshal.PtrToStringUni(this.Buffer, this.Length / 2);
        }

        public AnsiString ToAnsiString()
        {
            NtStatus status;
            AnsiString ansiStr = new AnsiString();

            if ((status = Win32.RtlUnicodeStringToAnsiString(ref ansiStr, ref this, true)) >= NtStatus.Error)
                throw new Win32Exception((int)status);

            return ansiStr;
        }

        public override string ToString()
        {
            return this.Read();
        }
    }
    #endregion

    #region AnsiString
    [StructLayout(LayoutKind.Sequential)]
    internal struct AnsiString : IDisposable
    {
        public AnsiString(string str)
        {
            UnicodeString unicodeStr;

            unicodeStr = new UnicodeString(str);
            this = unicodeStr.ToAnsiString();
            unicodeStr.Dispose();
        }

        public ushort Length;
        public ushort MaximumLength;
        public IntPtr Buffer;

        public void Dispose()
        {
            if (this.Buffer == IntPtr.Zero)
                return;

            Win32.RtlFreeAnsiString(ref this);
            this.Buffer = IntPtr.Zero;
        }

        public UnicodeString ToUnicodeString()
        {
            NtStatus status;
            UnicodeString unicodeStr = new UnicodeString();

            if ((status = Win32.RtlAnsiStringToUnicodeString(ref unicodeStr, ref this, true)) >= NtStatus.Error)
                throw new Win32Exception((int)status);

            return unicodeStr;
        }
    }
    #endregion
}
