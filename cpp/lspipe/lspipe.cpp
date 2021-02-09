#include <lspipe.hpp>
#include <locale>

void GetError(DWORD ecode);
ULONG GetIdFromPipeName(std::wstring name, ULONG error);
ULONG GetIdOfEventRoot(void);
ULONG GetNameOfPipeHandler(ULONG pid);
ULONG GetPipeHandler(const HANDLE& h);
void GetPipeInfo(std::wstring name, const ULONG& ci, const ULONG& mi);

int wmain(void) {
  ULONG *ver = *(ULONG (*)[2])0x7FFE026C;
  if (100 > (ver[0] * 10 + ver[1])) {
    std::wcout << L"Win10 or higher is required." << std::endl;
    return 1;
  }

  std::locale::global(std::locale(""));
  std::unique_ptr<HANDLE, AutoHelper<HANDLE, AutoHandle>> pipes(::CreateFile(
    L"\\\\.\\pipe\\", GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, 0, nullptr
  ));
  if (INVALID_HANDLE_VALUE == pipes.get()) {
    GetError(LastWin32);
    return 1;
  }

  BOOLEAN query = TRUE;
  IO_STATUS_BLOCK isb{};
  std::vector<BYTE> buf(4096);
  std::wcout << std::left << std::setw(43) << L"Pipe Name"
             << std::right << std::setw(5) << L"CI"
                           << std::setw(5) << L"MI" << L" Handlers\n"
             << std::left << std::setw(43) << L"---------"
             << std::right << std::setw(5) << L"---"
                           << std::setw(5) << L"---" << L" --------" << std::endl;
  while (1) {
    if (!NT_SUCCESS(::NtQueryDirectoryFile(
      pipes.get(), nullptr, nullptr, nullptr, &isb, &buf[0], 4096, FileDirectoryInformation,
      FALSE, nullptr, query
    ))) break;

    auto fdi = reinterpret_cast<PFILE_DIRECTORY_INFORMATION>(&buf[0]);
    while (1) {
      std::wstring name(&fdi->FileName[0], fdi->FileNameLength / 2);
      GetPipeInfo(name, fdi->EndOfFile.LowPart, fdi->AllocationSize.LowPart);
      if (0 == fdi->NextEntryOffset) break;
      fdi = reinterpret_cast<PFILE_DIRECTORY_INFORMATION>(
        reinterpret_cast<PBYTE>(fdi) + fdi->NextEntryOffset
      );
    }

    query = FALSE;
  }

  return 0;
}

void GetError(DWORD ecode) {
  HLOCAL loc{};
  DWORD size{};
  std::unique_ptr<HLOCAL, AutoHelper<HLOCAL, AutoLocals>> local(((
    size = FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
      nullptr, LastWin32 == ecode ? ::GetLastError() : ecode,
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<LPWSTR>(&loc), 0, nullptr
  )), loc));
  std::wstring msg(0 != size ? reinterpret_cast<LPWSTR>(loc)
                             : L"Unknown error has been occured...");
  std::wcout << L"[!] " << msg.substr(0, msg.length() - sizeof(WCHAR)) << std::endl;
}

/*
 * just extracts PID from pipe name if it's possible
 * returns zero on failure
 * useful when there are no SYSTEM privileges
 */
ULONG GetIdFromPipeName(std::wstring name, ULONG error) {
  std::wsmatch match;

  if (ERROR_ACCESS_DENIED == error) {
    const std::wregex re1(Winsock2, std::regex_constants::icase);
    const std::wregex re2(WmiEvent, std::regex_constants::icase);

    if (std::regex_match(name, match, re1))
      return wcstoul(match.str(1).c_str(), nullptr, 16);

    if (std::regex_match(name, match, re2))
      return GetIdOfEventRoot();
  }

  if (ERROR_PIPE_BUSY == error) {
    const std::wregex re3(Chromium, std::regex_constants::icase);
    const std::wregex re4(MsysPipe, std::regex_constants::icase);

    if (std::regex_match(name, match, re3) ||
        std::regex_match(name, match, re4))
      return wcstoul(match.str(1).c_str(), nullptr, 0);
  }

  return 0;
}

/*
 * just retrieves sihost.exe parent which is the holder of
 * PIPE_EVENTROOT\CIMV2SCM EVENT PROVIDER
 * returns zero on failure
 * useful when there are no SYSTEM privileges
 */
ULONG GetIdOfEventRoot(void) {
  ULONG ret = 0;
  auto nts = ::NtQuerySystemInformation(SystemProcessInformation, nullptr, 0, &ret);
  if (STATUS_INFO_LENGTH_MISMATCH != nts) {
    GetError(::RtlNtStatusToDosError(nts));
    return 0;
  }

  std::vector<BYTE> buf(static_cast<SIZE_T>(ret));
  nts = ::NtQuerySystemInformation(SystemProcessInformation, &buf[0], ret, nullptr);
  if (!NT_SUCCESS(nts)) {
    GetError(::RtlNtStatusToDosError(nts));
    return 0;
  }

  auto spi = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(&buf[0]);
  while (spi->NextEntryOffset) {
    if (0 != spi->ImageName.Length) { // except empty name (Idle)
      if (0 == _wcsicmp(spi->ImageName.Buffer, L"sihost.exe")) {
        ret = reinterpret_cast<ULONGLONG>(spi->InheritedFromUniqueProcessId);
        break;
      }
    }
    spi = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(
      reinterpret_cast<LPBYTE>(spi) + spi->NextEntryOffset
    );
  }

  return ret;
}

ULONG GetNameOfPipeHandler(ULONG pid) {
  NTSTATUS nts{};
  std::wstring buf;
  buf.reserve(MAX_PATH);
  SYSTEM_PROCESS_ID_INFORMATION spii{};

  spii.ProcessId = reinterpret_cast<HANDLE>(static_cast<ULONGLONG>(pid));
  spii.ImageName.MaximumLength = MAX_PATH;
  spii.ImageName.Buffer = &buf[0];

  nts = ::NtQuerySystemInformation(SystemProcessIdInformation, &spii, sizeof(spii), nullptr);
  if (!NT_SUCCESS(nts)) return ::RtlNtStatusToDosError(nts);

  buf = spii.ImageName.Buffer;
  buf = buf.substr(buf.find_last_of(L"\\") + 1, buf.length());
  std::wcout << buf << L" (" << pid << L")";

  return ERROR_SUCCESS;
}

ULONG GetPipeHandler(const HANDLE& h) {
  ULONG size{};
  IO_STATUS_BLOCK isb{};
  NTSTATUS nts = STATUS_INFO_LENGTH_MISMATCH;
  std::vector<BYTE> buf(sizeof(FILE_PROCESS_IDS_USING_FILE_INFORMATION));

  do { // iterate till not getting nearest to real size of buffer (one pass may be enough)
    size = static_cast<ULONG>(buf.size());
    nts = ::NtQueryInformationFile(h, &isb, &buf[0], size, FileProcessIdsUsingFileInformation);
    if (STATUS_INFO_LENGTH_MISMATCH != nts) break; // prevent resize buffer
    buf.resize(buf.size() * 2);
  } while (STATUS_INFO_LENGTH_MISMATCH == nts);

  if (!NT_SUCCESS(nts)) {
    std::vector<BYTE> ().swap(buf);
    return ::RtlNtStatusToDosError(nts);
  }

  auto pids = reinterpret_cast<PFILE_PROCESS_IDS_USING_FILE_INFORMATION>(&buf[0]);
  for (ULONG i = 0; i < pids->NumberOfProcessIdsInList; i++) {
    if (ERROR_SUCCESS != GetNameOfPipeHandler(static_cast<ULONG>(pids->ProcessIdList[i])))
      std::wcout << L"n/a";

    if ((i + 1) != pids->NumberOfProcessIdsInList)
      std::wcout << L", ";
  }
  std::vector<BYTE> ().swap(buf);

  return ERROR_SUCCESS;
}

void GetPipeInfo(std::wstring name, const ULONG& ci, const ULONG& mi) {
  std::wcout << std::left << std::setw(43) << name
             << std::right << std::setw(5) << ci
                           << std::setw(5) << static_cast<LONG>(mi)
                           << L" ";
  std::wstring fullname = L"\\\\.\\pipe\\" + name;
  std::unique_ptr<HANDLE, AutoHelper<HANDLE, AutoHandle>> pipe(::CreateFile(
    fullname.c_str(), 0, 0, nullptr, OPEN_EXISTING, 0, nullptr
  ));
  ULONG error = ::GetLastError();
  if (INVALID_HANDLE_VALUE == pipe.get()) {
    if (ERROR_ACCESS_DENIED == error || ERROR_PIPE_BUSY == error) {
      ULONG pid = GetIdFromPipeName(name, error);
      if (0 == pid) { // cannot retrieve PID, return last error
        GetError(error);
        return;
      }

      error = GetNameOfPipeHandler(pid);
      if (ERROR_SUCCESS != error) { // cannot retrieve process name
        GetError(error);
        return;
      }

      std::wcout << std::endl;
      return;
    }

    GetError(error);
    return;
  }

  if (ERROR_SUCCESS != GetPipeHandler(pipe.get())) {
    GetError(LastWin32);
    return;
  }

  std::wcout << std::endl;
}
