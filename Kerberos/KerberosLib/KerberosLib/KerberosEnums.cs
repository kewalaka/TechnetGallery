using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace KerberosLib
{
    public enum KERB_PROTOCOL_MESSAGE_TYPE
    {
        KerbDebugRequestMessage = 0,
        KerbQueryTicketCacheMessage = 1,
        KerbChangeMachinePasswordMessage = 2,
        KerbVerifyPacMessage = 3,
        KerbRetrieveTicketMessage = 4,
        KerbUpdateAddressesMessage = 5,
        KerbPurgeTicketCacheMessage = 6,
        KerbChangePasswordMessage = 7,
        KerbRetrieveEncodedTicketMessage = 8,
        KerbDecryptDataMessage = 9,
        KerbAddBindingCacheEntryMessage = 10,
        KerbSetPasswordMessage = 11
    }

    [Flags]
    public enum KERB_TICKET_FLAGS : long
    {
        Reserved = 0x80000000,
        Forwardable = 0x40000000,
        Forwarded = 0x20000000,
        Proxiable = 0x10000000,
        Proxy = 0x08000000,
        Postdate = 0x04000000,
        Postdated = 0x02000000,
        Invalid = 0x01000000,
        Renewable = 0x00800000,
        Initial = 0x00400000,
        PreAuthent = 0x00200000,
        HwAuthent = 0x00100000,
        OkAsDelegate = 0x00040000,
        NameCanonicalize = 0x00010000
    }

    public enum KERB_TICKET_ENCRYPTIONTYPE
    {
        UNKNOWN = -1,
        NULL = 0,
        DES_CBC_CRC = 1,
        DES_CBC_MD4 = 2,
        DES_CBC_MD5 = 3,
        RESERVED4 = 4,
        DES3_CBC_MD5 = 5,
        RESERVED6 = 6,
        DES3_CBC_SHA1 = 7,
        DSAWITHSHA1_CMSOID = 9,
        MD5WITHRSAENCRYPTION_CMSOID = 10,
        SHA1WITHRSAENCRYPTION_CMSOID = 11,
        RC2CBC_ENVOID = 12,
        RSAENCRYPTION_ENVOID = 13,
        RSAES_OAEP_ENV_OID = 14,
        DES_EDE3_CBC_ENV_OID = 15,
        DES3_CBC_SHA1_KD = 16,
        AES128_CTS_HMAC_SHA1_96 = 17,
        AES256_CTS_HMAC_SHA1_96 = 18,
        RC4_HMAC = 23,
        RC4_HMAC_EXP = 24,
        SUBKEY_KEYMATERIAL = 65,
        RC4_MD4 = -128,
        RC4_HMAC_OLD = -133,
        RC4_HMAC_OLD_EXP = -135
    }
}
