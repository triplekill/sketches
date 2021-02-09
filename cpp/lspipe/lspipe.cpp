#include <lspipe.hpp>
#include <locale>

void GetError(DWORD ecode);
//DWORD GetPrivilege(ULONG privname, BOOLEAN enable);
DWORD GetPipeNameHandler(ULONG pid);
DWORD GetPipeHandler(const HANDLE& h);
void GetPipeInfo(std::wstring name, const DWORD& cur, const LONG& max);

int wmain(void) {
  std::locale::global(std::locale(""));

  /*
  DWORD err = GetPrivilege(SE_DEBUG_PRIVILEGE, TRUE);
  if (ERROR_SUCCESS != err) {
    GetError(err);
  }
  */

  std::unique_ptr<HANDLE, CHelper<HANDLE, ClrHandle>> pipes(::CreateFile(
    L"\\\\.\\pipe\\", GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, 0, nullptr
  ));
  if (INVALID_HANDLE_VALUE == pipes.get()) {
    GetError(LAST);
    return 1;
  }

  BOOLEAN query = TRUE;
  IO_STATUS_BLOCK isb{};
  std::vector<BYTE> buf(4096);
  std::wcout << std::left << std::setw(43) << L"Pipe Name"
             << std::right << std::setw(5) << L"Cur"
                           << std::setw(5) << L"Max" << L" Srv\\Client\n"
             << std::left << std::setw(43) << L"---------"
             << std::right << std::setw(5) << L"---"
                           << std::setw(5) << L"---" << L" ----------" << std::endl;
  while (1) {
    if (!NT_SUCCESS(::NtQueryDirectoryFile(
      pipes.get(), nullptr, nullptr, 0, &isb, &buf[0], 4096, FileDirectoryInformation,
      FALSE, nullptr, query
    ))) break;

    auto fdi = reinterpret_cast<PFILE_DIRECTORY_INFORMATION>(&buf[0]);
    while (1) {
      std::wstring name(&fdi->FileName[0], fdi->FileNameLength / 2);
      GetPipeInfo(name, fdi->EndOfFile.LowPart, fdi->AllocationSize.LowPart);
      if (0 == fdi->NextEntryOffset) break;
      fdi = reinterpret_cast<PFILE_DIRECTORY_INFORMATION>(
        reinterpret_cast<PCHAR>(fdi) + fdi->NextEntryOffset
      );
    }

    query = FALSE;
  }

  return 0;
}

void GetError(DWORD ecode) {
  HLOCAL buf{};
  DWORD   sz{};
  std::unique_ptr<HLOCAL, CHelper<HLOCAL, ClrLocal>> local(((sz = ::FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
    nullptr, LAST == ecode ? ::GetLastError() : ecode,
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
    reinterpret_cast<LPWSTR>(&buf), 0, nullptr
  )), buf));
  std::wstring msg(0 != sz ? reinterpret_cast<LPWSTR>(buf)
                           : L"Unknown error has been occured...");
  std::wcout << L"[!] " << msg.substr(0, msg.length() - sizeof(WCHAR)) << std::endl;
}

/*
DWORD GetPrivilege(ULONG privname, BOOLEAN enable) {
  BOOLEAN enabled{};
  NTSTATUS nts = ::RtlAdjustPrivilege(privname, enable, FALSE, &enabled);
  if (!NT_SUCCESS(nts)) return ::RtlNtStatusToDosError(nts);

  return ERROR_SUCCESS;
}
*/

DWORD GetPipeHandler(const HANDLE& h) {
  ULONG sz{};
  IO_STATUS_BLOCK isb{};
  NTSTATUS nts = STATUS_INFO_LENGTH_MISMATCH;
  std::vector<BYTE> buf(sizeof(FILE_PROCESS_IDS_USING_FILE_INFORMATION));

  do { // iterate till not getting nearest to real size of buffer (one pass may be enough)
    sz = static_cast<ULONG>(buf.size());
    nts = ::NtQueryInformationFile(h, &isb, &buf[0], sz, FileProcessIdsUsingFileInformation);
    if (STATUS_INFO_LENGTH_MISMATCH != nts) break; // prevent resize buffer
    buf.resize(buf.size() * 2);
  } while (STATUS_INFO_LENGTH_MISMATCH == nts);

  if (!NT_SUCCESS(nts)) {
    std::vector<BYTE> ().swap(buf);
    return ::RtlNtStatusToDosError(nts);
  }

  auto pids = reinterpret_cast<PFILE_PROCESS_IDS_USING_FILE_INFORMATION>(&buf[0]);
  for (ULONG i = 0; i < pids->NumberOfProcessIdsInList; i++) {
    if (ERROR_SUCCESS != GetPipeNameHandler(static_cast<ULONG>(pids->ProcessIdsList[i])))
      std::wcout << L"n/a";

    if ((i + 1) != pids->NumberOfProcessIdsInList)
      std::wcout << L", ";
  }
  std::vector<BYTE> ().swap(buf);

  return ERROR_SUCCESS;
}

DWORD GetPipeNameHandler(ULONG pid) {
  NTSTATUS nts{};
  std::wstring buf;
  buf.reserve(MAX_PATH);
  SYSTEM_PROCESS_ID_INFORMATION spii{};

  spii.ProcessId = reinterpret_cast<HANDLE>(pid);
  spii.ImageName.MaximumLength = MAX_PATH;
  spii.ImageName.Buffer = &buf[0];

  nts = ::NtQuerySystemInformation(SystemProcessIdInformation, &spii, sizeof(spii), nullptr);
  if (!NT_SUCCESS(nts)) return ::RtlNtStatusToDosError(nts);

  buf = spii.ImageName.Buffer;
  buf = buf.substr(buf.find_last_of(L"\\") + 1, buf.length());
  std::wcout << buf << L" (" << pid << L")";

  return ERROR_SUCCESS;
}

void GetPipeInfo(std::wstring name, const DWORD& cur, const LONG& max) {
  std::wcout << std::left << std::setw(43) << name
             << std::right << std::setw(5) << cur
                           << std::setw(5) << max
                           << L" ";
  std::wstring fullname = L"\\\\.\\pipe\\" + name;
  std::unique_ptr<HANDLE, CHelper<HANDLE, ClrHandle>> pipe(::CreateFile(
    fullname.c_str(), 0, 0, nullptr, OPEN_EXISTING, 0, nullptr
  ));

  if (INVALID_HANDLE_VALUE == pipe.get()) {
    GetError(LAST);
    return;
  }

  if (ERROR_SUCCESS != GetPipeHandler(pipe.get())) {
    GetError(LAST);
    return;
  }

  std::wcout << std::endl;
}
