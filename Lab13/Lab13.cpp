
#include "stdafx.h"
#include "Lab13.h"
#include <TlHelp32.h>
#include <windowsx.h>

#define MAX_LOADSTRING 100

// Global Variables:
HINSTANCE hInst;								
TCHAR szTitle[MAX_LOADSTRING];					
TCHAR szWindowClass[MAX_LOADSTRING];			

HWND listBox1, listBox2;
HMENU hPopupMenu;

#define N 500

int procCount = 0;
PROCESSENTRY32 procs[N];

int moduleCount = 0;
MODULEENTRY32 modules[N];

ATOM				MyRegisterClass(HINSTANCE hInstance);
BOOL				InitInstance(HINSTANCE, int);
LRESULT CALLBACK	WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK	About(HWND, UINT, WPARAM, LPARAM);

int APIENTRY _tWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPTSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);

	MSG msg;
	HACCEL hAccelTable;

	LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadString(hInstance, IDC_LAB13, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);

	// Perform application initialization:
	if (!InitInstance (hInstance, nCmdShow))
	{
		return FALSE;
	}

	hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_LAB13));

	while (GetMessage(&msg, NULL, 0, 0))
	{
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return (int) msg.wParam;
}

ATOM MyRegisterClass(HINSTANCE hInstance)
{
	WNDCLASSEX wcex;

	wcex.cbSize = sizeof(WNDCLASSEX);

	wcex.style			= CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc	= WndProc;
	wcex.cbClsExtra		= 0;
	wcex.cbWndExtra		= 0;
	wcex.hInstance		= hInstance;
	wcex.hIcon			= LoadIcon(hInstance, MAKEINTRESOURCE(IDI_LAB13));
	wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground = CreateSolidBrush(RGB(0, 119, 179));
	wcex.lpszMenuName	= MAKEINTRESOURCE(IDC_LAB13);
	wcex.lpszClassName	= szWindowClass;
	wcex.hIconSm		= LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

	return RegisterClassEx(&wcex);
}

#define LISTBOX1_ID 1001
#define LISTBOX2_ID 1002

void ClearListBox(HWND listBox) {
	while (SendMessage(listBox, LB_GETCOUNT, 0, NULL))
		SendMessage(listBox, LB_DELETESTRING, 0, NULL);
}

void ShowProcs()
{
	procCount = 0;
	procs[0].dwSize = sizeof(PROCESSENTRY32);

	HANDLE toolHelp = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	bool result = Process32First(toolHelp, &procs[0]);
	while (result)
	{
		procCount++;
		procs[procCount].dwSize = sizeof(PROCESSENTRY32);
		result = Process32Next(toolHelp, &procs[procCount]);
	}
	CloseHandle(toolHelp);

	ClearListBox(listBox1);
	for (int i = 0; i < procCount; i++)
		SendMessage(listBox1, LB_ADDSTRING, 0, (LPARAM)procs[i].szExeFile);
}

void ShowModules(PROCESSENTRY32 proc)
{
	moduleCount = 0;
	modules[0].dwSize = sizeof(MODULEENTRY32);

	HANDLE toolHelp = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, proc.th32ProcessID);
	bool result = Module32First(toolHelp, &modules[0]);
	while (result)
	{
		moduleCount++;
		modules[moduleCount].dwSize = sizeof(MODULEENTRY32);
		result = Module32Next(toolHelp, &modules[moduleCount]);
	}
	CloseHandle(toolHelp);

	ClearListBox(listBox2);
	for (int i = 0; i < moduleCount; ++i)
		SendMessage(listBox2, LB_ADDSTRING, 0, (LPARAM)modules[i].szModule);
}

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   HWND hWnd;

   hInst = hInstance; 

   hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, 600, 500, NULL, NULL, hInstance, NULL);

   listBox1 = CreateWindow(L"LISTBOX", L"Processes", WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | LBS_NOTIFY,
	   20, 50, 250, 400, hWnd, (HMENU)LISTBOX1_ID, hInstance, NULL);
   listBox2 = CreateWindow(L"LISTBOX", L"Modules", WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL,
	   300, 50, 250, 400, hWnd, (HMENU)LISTBOX2_ID, hInstance, NULL);

   ShowProcs();

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

#define ID_IDLE 10
#define ID_NORMAL 11
#define ID_HIGH 12
#define ID_REAL_TIME 13

void SetPriority(DWORD priorityClass) {
	int itemId = SendMessage(listBox1, LB_GETCURSEL, 0, NULL);
	if (itemId != -1) {
		HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, procs[itemId].th32ProcessID);
		SetPriorityClass(hProcess, priorityClass);
		CloseHandle(hProcess);
	}
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	int wmId, wmEvent;
	PAINTSTRUCT ps;
	HDC hdc;

	switch (message)
	{
	case WM_COMMAND:
		wmId    = LOWORD(wParam);
		wmEvent = HIWORD(wParam);
		switch (wmId)
		{
		case LISTBOX1_ID:
			if (wmEvent == LBN_SELCHANGE)
			{
				int itemId = SendMessage(listBox1, LB_GETCURSEL, 0, NULL);
				if (itemId != -1)
					ShowModules(procs[itemId]);
			}
			break;
		case ID_IDLE:
			SetPriority(IDLE_PRIORITY_CLASS);
			break;
		case ID_NORMAL:
			SetPriority(NORMAL_PRIORITY_CLASS);
			break;
		case ID_HIGH:
			SetPriority(HIGH_PRIORITY_CLASS);
			break;
		case ID_REAL_TIME:
			SetPriority(REALTIME_PRIORITY_CLASS);
			break;
		case IDM_ABOUT:
			DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
			break;
		case IDM_EXIT:
			DestroyWindow(hWnd);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
		break;
	case WM_CONTEXTMENU:
		if ((HWND)wParam == listBox1) {
			int itemId = SendMessage(listBox1, LB_GETCURSEL, 0, NULL);
			if (itemId != -1) {
				HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, procs[itemId].th32ProcessID);
				int pC = GetPriorityClass(hProcess);
				CloseHandle(hProcess);

				hPopupMenu = CreatePopupMenu();
				AppendMenu(hPopupMenu, pC == IDLE_PRIORITY_CLASS ? MF_CHECKED : MF_STRING, ID_IDLE, L"Низкий");
				AppendMenu(hPopupMenu, pC == NORMAL_PRIORITY_CLASS ? MF_CHECKED : MF_STRING, ID_NORMAL, L"Нормальный");
				AppendMenu(hPopupMenu, pC == HIGH_PRIORITY_CLASS ? MF_CHECKED : MF_STRING, ID_HIGH, L"Высокий");
				AppendMenu(hPopupMenu, pC == REALTIME_PRIORITY_CLASS ? MF_CHECKED : MF_STRING, ID_REAL_TIME, L"Реального времени");
				TrackPopupMenu(hPopupMenu, TPM_TOPALIGN | TPM_LEFTALIGN, GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam), 0, hWnd, NULL);
			}
		}
		break;
	case WM_CTLCOLORLISTBOX:
	{
		static HBRUSH hBrush = CreateSolidBrush(RGB(230, 247, 255));
		HDC hdcStatic = (HDC)wParam;
		SetTextColor(hdcStatic, RGB(0, 3, 69));
		SetBkColor(hdcStatic, RGB(230, 247, 255));
		return (INT_PTR)hBrush;
	}
	case WM_PAINT:
		hdc = BeginPaint(hWnd, &ps);
		SetTextColor(hdc, RGB(230, 247, 255));
		SetBkColor(hdc, RGB(0, 119, 179));
		TextOut(hdc, 105, 20, L"Процессы:", wcslen(L"Процессы:"));
		TextOut(hdc, 390, 20, L"Модули:", wcslen(L"Модули:"));
		EndPaint(hWnd, &ps);
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}

INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message)
	{
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;

	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
		{
			EndDialog(hDlg, LOWORD(wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	return (INT_PTR)FALSE;
}
