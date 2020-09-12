#include <lspipe.hpp>
#include <locale>

void getlasterror(const DWORD err);
DWORD getpipehandler(const HANDLE& h);
DWORD getpipeowner(const HANDLE& h);
DWORD getpipelocalinfo(const HANDLE& h);
void gatheringinfo(const std::wstring& fullname);

int wmain(void) {
  std::locale::global(std::locale(""));
  std::unique_ptr<HANDLE, HandleHelper> pipes(::CreateFile(
    L"\\\\.\\pipe\\", GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, 0, nullptr
  ));
  if (!pipes) {
    getlasterror(0L);
    return 1;
  }

  BOOLEAN query = TRUE;
  IO_STATUS_BLOCK isb{};
  std::vector<BYTE> buf(4096);
  while (1) {
    if (!NT_SUCCESS(::NtQueryDirectoryFile(
      pipes.get(), nullptr, nullptr, 0, &isb, &buf[0], 4096,
      FileDirectoryInformation, FALSE, nullptr, query
    ))) break;

    auto fdi = reinterpret_cast<FILE_DIRECTORY_INFORMATION *>(&buf[0]);
    while(1) {
      std::wstring name(&fdi->FileName[0], fdi->FileNameLength / 2);
      std::wcout << name << std::endl;
      name = L"\\\\.\\pipe\\" + name;
      gatheringinfo(name);
      std::wcout << std::setw(12) << L"Instances: " << fdi->EndOfFile.LowPart << L"/"
                 << fdi->AllocationSize.LowPart << L" (cur/max)" << std::endl;
      std::wcout << std::endl;
      if (0 == fdi->NextEntryOffset) break;
      fdi = reinterpret_cast<PFILE_DIRECTORY_INFORMATION>(
        reinterpret_cast<PCHAR>(fdi) + fdi->NextEntryOffset
      );
    }
    query = FALSE;
  }

  return 0;
}

void getlasterror(const DWORD err) {
  HLOCAL buf{};
  DWORD   sz{};
  std::unique_ptr<HLOCAL, LocalHelper<HLOCAL>> error_message(((sz = FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
    nullptr, 0L == err ? ::GetLastError() : err,
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
    reinterpret_cast<LPWSTR>(&buf), 0, nullptr
  )), buf));
  std::wstring msg(0 != sz ? reinterpret_cast<LPWSTR>(buf)
                           : L"Unknown error has been occured...");
  std::wcout << L"[!] " << msg.substr(0, msg.length() - sizeof(WCHAR)) << std::endl;
}

void gatheringinfo(const std::wstring& fullname) {
  std::unique_ptr<HANDLE, HandleHelper> pipe(
    ::CreateFile(fullname.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, 0, nullptr
  ));
  auto errchk = [](const DWORD err) {
    if (ERROR_SUCCESS != err) {
      std::wcout << std::setw(9);
      getlasterror(err);
    }
  };

  errchk(getpipehandler(pipe.get()));
  errchk(getpipeowner(pipe.get()));
  errchk(getpipelocalinfo(pipe.get()));
}

DWORD getpipelocalinfo(const HANDLE& h) {
  IO_STATUS_BLOCK isb{};
  FILE_PIPE_LOCAL_INFORMATION info{};
  const WCHAR *config[] = {PipeConfiguration(CArray)};
  const WCHAR *status[] = {PipeState(CArray)};

  NTSTATUS nts = ::NtQueryInformationFile(
    h, &isb, &info, sizeof(FILE_PIPE_LOCAL_INFORMATION), FilePipeLocalInformation
  );
  if (!NT_SUCCESS(nts)) return ::RtlNtStatusToDosError(nts);

  std::wcout << std::setw(12) << L"Config: " << config[info.NamedPipeConfiguration] << L"\n"
             << std::setw(12) << L"State: " << status[info.NamedPipeState] <<std::endl;

  return ERROR_SUCCESS;
}

DWORD getpipehandler(const HANDLE& h) {
  ULONG sz{};
  IO_STATUS_BLOCK isb{};
  NTSTATUS nts = STATUS_INFO_LENGTH_MISMATCH;
  std::vector<BYTE> buf(sizeof(FILE_PROCESS_IDS_USING_FILE_INFORMATION));

  do { // iterate till not getting nearest to real size of buffer (one pass can be enought)
    sz = static_cast<ULONG>(buf.size());
    nts = ::NtQueryInformationFile(h, &isb, &buf[0], sz, FileProcessIdsUsingFileInformation);
    if (STATUS_INFO_LENGTH_MISMATCH != nts) break;
    buf.resize(buf.size() * 2);
  } while (STATUS_INFO_LENGTH_MISMATCH == nts);

  if (!NT_SUCCESS(nts)) {
    std::vector<BYTE> ().swap(buf);
    return ::RtlNtStatusToDosError(nts);
  }

  auto pids = reinterpret_cast<FILE_PROCESS_IDS_USING_FILE_INFORMATION *>(&buf[0]);
  for (ULONG i = 0; i < pids->NumberOfProcessIdsInList; i++) {
    std::wcout << std::setw(12) << L"Handler: " << pids->ProcessIdList[i] << std::endl;
  }
  std::vector<BYTE> ().swap(buf);

  return ERROR_SUCCESS;
}

DWORD getpipeowner(const HANDLE& h) {
  PSID sid{};
  PSECURITY_DESCRIPTOR psd{};
  DWORD err = ::GetSecurityInfo( // getting pointer on owner's SID
    h, SE_FILE_OBJECT, OWNER_SECURITY_INFORMATION, &sid, nullptr, nullptr, nullptr, &psd
  );
  std::unique_ptr<PSECURITY_DESCRIPTOR, LocalHelper<PSECURITY_DESCRIPTOR>> local(psd);

  if (ERROR_SUCCESS != err) return err;

  DWORD nsz{}, dsz{}; // first pass, getting real buffers sizes
  SID_NAME_USE snu{}; // take but not check
  BOOL status = ::LookupAccountSid(nullptr, sid, nullptr, &nsz, nullptr, &dsz, &snu);
  err = ::GetLastError();
  if (!status && ERROR_INSUFFICIENT_BUFFER != err) return err;

  std::vector<wchar_t> name(nsz);
  std::vector<wchar_t> domain(dsz);
  status = ::LookupAccountSid(nullptr, sid, &name[0], &nsz, &domain[0], &dsz, &snu);
  if (!status) return ::GetLastError();

  std::wcout << std::setw(12) << L"Owner: " << std::wstring(domain.data(), domain.size())
             << L"\\" << std::wstring(name.data(), name.size()) << std::endl;

  return ERROR_SUCCESS;
}
