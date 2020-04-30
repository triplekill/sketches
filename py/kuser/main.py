from ctypes   import POINTER, cast, c_void_p
from wintypes import KUSER_SHARED_DATA

PROCESSOR_FEATURES = (
  'PF_FLOATING_POINT_PRECISION_ERRATA',
  'PF_FLOATING_POINT_EMULATED',
  'PF_COMPARE_EXCHANGE_DOUBLE',
  'PF_MMX_INSTRUCTIONS_AVAILABLE',
  'PF_PPC_MOVEMEM_64BIT_OK',
  'PF_ALPHA_BYTE_INSTRUCTIONS',
  'PF_XMMI_INSTRUCTIONS_AVAILABLE',
  'PF_3DNOW_INSTRUCTIONS_AVAILABLE',
  'PF_RDTSC_INSTRUCTION_AVAILABLE',
  'PF_PAE_ENABLED',
  'PF_XMMI64_INSTRUCTIONS_AVAILABLE',
  'PF_SSE_DAZ_MODE_AVAILABLE',
  'PF_NX_ENABLED',
  'PF_SSE3_INSTRUCTIONS_AVAILABLE',
  'PF_COMPARE_EXCHANGE128',
  'PF_COMPARE64_EXCHANGE128',
  'PF_CHANNELS_ENABLED',
  'PF_XSAVE_ENABLED',
  'PF_ARM_VFP_32_REGISTERS_AVAILABLE',
  'PF_ARM_NEON_INSTRUCTIONS_AVAILABLE',
  'PF_SECOND_LEVEL_ADDRESS_TRANSLATION',
  'PF_VIRT_FIRMWARE_ENABLED',
  'PF_RDWRFSGSBASE_AVAILABLE',
  'PF_FASTFAIL_AVAILABLE',
  'PF_ARM_DIVIDE_INSTRUCTION_AVAILABLE',
  'PF_ARM_64BIT_LOADSTORE_ATOMIC',
  'PF_ARM_EXTERNAL_CACHE_AVAILABLE',
  'PF_ARM_FMAC_INSTRUCTIONS_AVAILABLE',
  'PF_RDRAND_INSTRUCTION_AVAILABLE',
  'PF_ARM_V8_INSTRUCTIONS_AVAILABLE',
  'PF_ARM_V8_CRYPTO_INSTRUCTIONS_AVAILABLE',
  'PF_ARM_V8_CRC32_INSTRUCTIONS_AVAILABLE',
  'PF_RDTSCP_INSTRUCTION_AVAILABLE'
)

SHARED_GLOBAL_FLAGS = {
  'QPC_BYPASS_ENABLED'    : 0x01,
  'QPC_BYPASS_USE_MFENCE' : 0x10,
  'QPC_BYPASS_USE_LFENCE' : 0x20,
  'QPC_BYPASS_A73_ERRATA' : 0x40,
  'QPC_BYPASS_USE_RDTSCP' : 0x80
}

if __name__ == '__main__':
   k = cast(c_void_p(0x7FFE0000), POINTER(KUSER_SHARED_DATA)).contents
   print('{0} ({1}) [Version {2}.{3}.{4}] alt: {5}'.format(
      k.NtProductType, k.ProductTypeIsValid,
      k.NtMajorVersion, k.NtMinorVersion, k.NtBuildNumber,
      k.AlternativeArchitecture
   ))
   print('System bitness  : {0}'.format(
      'x64' if 9 == k.NativeProcessorArchitecture else 'x86' \
          if 0 == k.NativeProcessorArchitecture else 'Unknown'
   ))
   print('System path     : {0}'.format(k.NtSystemRoot))
   print('System time     : {0}'.format(k.SystemTime))
   print('System uptime   : {0}'.format(k.TickCount.TickCountQuad))
   print('Image file low  : {0}'.format(k.ImageNumberLow))
   print('Image file high : {0}'.format(k.ImageNumberHigh))
   print('Processor features\n-------------------')
   for x in filter(lambda x: x[1], zip(
     PROCESSOR_FEATURES, k.ProcessorFeatures[:len(PROCESSOR_FEATURES)]
   )): print('\t{0}'.format(x[0]))
   print('Shared global flags\n--------------------')
   for x in filter(
     lambda x: k.QpcData.Data.QpcBypassEnabled & SHARED_GLOBAL_FLAGS[x],
     SHARED_GLOBAL_FLAGS.keys()
   ): print('\t{0}'.format(x))
