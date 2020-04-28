#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include <Windows.h>
#include "include/dirent.h"
using namespace std;

#define TRUE 1
#define FALSE 0

struct {
	char path[100];
	ULONG maxcount;
} maxDirent;


SIZE_T* GetFileClusters(
	PCTSTR lpFileName,
	ULONG ClusterSize,
	ULONG* ClCount,
	ULONG* FileSize)
{
	HANDLE hFile;
	ULONG OutSize;
	ULONG Bytes, Cls, CnCount, r;
	SIZE_T* Clusters = NULL;
	BOOLEAN Result = FALSE;
	LARGE_INTEGER PrevVCN, Lcn;
	STARTING_VCN_INPUT_BUFFER InBuf;
	PRETRIEVAL_POINTERS_BUFFER OutBuf;
	hFile = CreateFile(lpFileName, GENERIC_READ, // FILE_READ_ATTRIBUTES
		FILE_SHARE_READ, // | FILE_SHARE_WRITE | FILE_SHARE_DELETE
		NULL, OPEN_EXISTING, 0, 0);

	if (hFile != INVALID_HANDLE_VALUE)
	{
		*FileSize = GetFileSize(hFile, NULL);
		OutSize = sizeof(RETRIEVAL_POINTERS_BUFFER) + (*FileSize / ClusterSize) * sizeof(OutBuf->Extents);
		OutBuf = (PRETRIEVAL_POINTERS_BUFFER)malloc(OutSize);
		InBuf.StartingVcn.QuadPart = 0;
		if (DeviceIoControl(hFile, FSCTL_GET_RETRIEVAL_POINTERS, &InBuf,
			sizeof(InBuf), OutBuf, OutSize, &Bytes, NULL))
		{
			*ClCount = (*FileSize + ClusterSize - 1) / ClusterSize;
			Clusters = (SIZE_T*)malloc(*ClCount * sizeof(SIZE_T));
			PrevVCN = OutBuf->StartingVcn;
			for (r = 0, Cls = 0; r < OutBuf->ExtentCount; r++)
			{
				Lcn = OutBuf->Extents[r].Lcn;
				for (CnCount = OutBuf->Extents[r].NextVcn.QuadPart - PrevVCN.QuadPart;
					CnCount;
					CnCount--, Cls++, Lcn.QuadPart++)
					Clusters[Cls] = Lcn.QuadPart;
				PrevVCN = OutBuf->Extents[r].NextVcn;
			}
		}
		free(OutBuf);
		CloseHandle(hFile);
	}
	return Clusters;
}

ULONG GetCountClusters(PCTSTR FilePath)
{
	ULONG64 d1 = 0, d2 = 0;
	char DriveName[4] = { 0 };
	ULONG SecPerCl, BtPerSec, ClusterSize, ClCount, FileSize, i;
	//memcpy(DriveName, FilePath, 4);
	wcstombs(DriveName, FilePath, 3);
	GetDiskFreeSpaceA(DriveName, &SecPerCl, &BtPerSec, NULL, NULL);
	ClusterSize = SecPerCl * BtPerSec;
	PSIZE_T x = GetFileClusters(FilePath, ClusterSize, &ClCount, &FileSize);
	if (x != NULL)
	{
		free(x);
		return ClCount;
	}
	return 0;
}


void Calculate(char* fullpath, ULONG ClCount) {
	if (ClCount > maxDirent.maxcount) {
		strcpy_s(maxDirent.path, 100, fullpath);
		maxDirent.maxcount = ClCount;
	}
}

const wchar_t* GetWC(const char* c)
{
	const size_t cSize = strlen(c) + 1;
	wchar_t* wc = new wchar_t[cSize];
	mbstowcs(wc, c, cSize);

	return wc;
}

void listdir(char* name, int indent)
{
	DIR* dir;
	struct dirent* entry;

	if (!(dir = opendir(name)))
		return;

	while ((entry = readdir(dir)) != NULL) {
		if (entry->d_type == DT_DIR) {
			char path[1024];
			if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
				continue;
			snprintf(path, sizeof(path), "%s\\%s", name, entry->d_name);
			printf("%*s[%s]\n", indent, "", entry->d_name);
			listdir(path, indent + 4);
		}
		else {
			//printf("%*s- %s\\%s size:%d\n", indent, "", name, entry->d_name, entry->d_namlen);
			char fullpath[100];
			sprintf(fullpath, "%s\\%s", name, entry->d_name);
			int ClCount = GetCountClusters(GetWC(fullpath));
			printf("%*s- %s = %d\n", indent, "", entry->d_name, ClCount);
			Calculate(fullpath, ClCount);
		}
	}
	closedir(dir);
}




int main()
{
	SetConsoleCP(1251);
	SetConsoleOutputCP(1251);

	char path[100];
	maxDirent.maxcount = 0;
	scanf_s("%s", path, (unsigned)sizeof(path));
	listdir(path, 0);
	cout << "\npath: " << maxDirent.path << ", \ncount: " << maxDirent.maxcount << '\n';
}