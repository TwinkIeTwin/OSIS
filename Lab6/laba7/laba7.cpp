// laba7.cpp : Определяет точку входа для приложения.
//

#include "stdafx.h"
#include "laba7.h"

class ImageMoving

{
private:
	int cx = 0;
	int cy = 0;
	int Xmax = 0;
	int Ymax = 0;
	int xdelta = 4;
	int ydelta = 4;
	int w = 0;
	int h = 0;
public:
	bool isNeedToMove = false;
	bool isVisible = false;
	bool isMirror = false;
	ImageMoving() {};
	ImageMoving(int x, int y, int MaxX, int MaxY, int width, int height);
	void getNextPos(int* x, int *y);
	~ImageMoving() {};
};

ImageMoving::ImageMoving(int x, int y, int MaxX, int MaxY, int width, int height)
{
	cx = x;
	cy = y;
	Xmax = MaxX;
	Ymax = MaxY;
	w = width;
	h = height;
}

void ImageMoving::getNextPos(int* x, int *y)
{
	if (!isNeedToMove)
	{
		*x = cx;
		*y = cy;
		return;
	}
	cy += ydelta;
	cx += xdelta;

	if (cx + w >= Xmax || cx <= 50)
	{
		xdelta = -xdelta;
		cx += 2 * xdelta;
		isMirror = !isMirror;
	}

	if (cy + h >= Ymax || cy <= 50)
	{
		ydelta = -ydelta;
		cy += 2 * ydelta;
	}

	*x = cx;
	*y = cy;
	return;
}

#define IDR_MAINFRAME 128
#define IDD_MOUSE_DIALOG 102
#define IDD_ABOUTBOX 103
#define IDM_ABOUT 104
#define IDM_EXIT 105
#define IDI_MOUSE 107
#define IDI_SMALL 108
#define IDC_MOUSE 109
#define ID_BUTTON_PaintField 11000
#define ID_BUTTON_CLEAR 11001
#define ID_LIST_FROM 11002
#define ID_LIST_TO 11003
#define ID_BUTTON_MOVE 11004
#define ID_EDIT_ADD 11005
#define ID_BUTTON_EXIT 11006
#define MAX_LOADSTRING 100

// Global Variables:
HWND hWndMainView;
HINSTANCE hInst; // current instance
TCHAR szTitle[MAX_LOADSTRING]; // The title bar text
TCHAR szWindowClass[MAX_LOADSTRING]; // the main window class name
// Forward declarations of functions included in this code module:
ATOM MyRegisterClass(HINSTANCE hInstance);
BOOL InitInstance(HINSTANCE, int);
LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK About(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK PaintFieldWindow(HWND, UINT, WPARAM, LPARAM);

int nCount = 0;
int startX[1000];
int startY[1000];
int endX[1000];
int endY[1000];
int nTextLen = 0;
TCHAR text[20];

HICON hIcon = (HICON)LoadImage(NULL, L"rocet.ico", IMAGE_ICON, 128, 128, LR_LOADFROMFILE);
HICON hIcon2 = (HICON)LoadImage(NULL, L"rocket_back.ico", IMAGE_ICON, 128, 128, LR_LOADFROMFILE);

int APIENTRY _tWinMain(HINSTANCE hInstance,
	HINSTANCE hPrevInstance,
	LPTSTR lpCmdLine,
	int nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
	// TODO: Place code here.
	MSG msg;
	HACCEL hAccelTable;
	// Initialize global strings
	LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadString(hInstance, IDC_MOUSE, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);
	// Perform application initialization:
	if (!InitInstance(hInstance, nCmdShow))
	{
		return FALSE;
	}
	hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_MOUSE));
	// Main message loop:
	while (GetMessage(&msg, NULL, 0, 0))
	{
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}
	return (int)msg.wParam;
}
//
// FUNCTION: MyRegisterClass()
//
// PURPOSE: Registers the window class.
//
// COMMENTS:
//
// This function and its usage are only necessary if you want this code
// to be compatible with Win32 systems prior to the 'RegisterClassEx'
// function that was added to Windows 95. It is important to call this function
// so that the application will get 'well formed' small icons associated
// with it.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
	WNDCLASSEX wcex;
	wcex.cbSize = sizeof(WNDCLASSEX);
	wcex.style = CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc = WndProc;
	wcex.cbClsExtra = 0;
	wcex.cbWndExtra = 0;
	wcex.hInstance = hInstance;
	wcex.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_MOUSE));
	wcex.hCursor = LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
	wcex.lpszMenuName = MAKEINTRESOURCE(IDC_MOUSE);
	wcex.lpszClassName = szWindowClass;
	wcex.hIconSm = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));
	return RegisterClassEx(&wcex);
}
//
// FUNCTION: InitInstance(HINSTANCE, int)
//
// PURPOSE: Saves instance handle and creates main window
//
// COMMENTS:
//
// In this function, we save the instance handle in a global variable and
// create and display the main program window.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
	HWND hWnd;
	hInst = hInstance; // Store instance handle in our global variable
	hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
		CW_USEDEFAULT, 0, 1280, 720, NULL, NULL, hInstance, NULL);
	if (!hWnd)
	{
		return FALSE;
	}
	ShowWindow(hWnd, nCmdShow);
	UpdateWindow(hWnd);
	return TRUE;
}
ImageMoving *mI = new ImageMoving[1000];
int ImagesCount = 0;
bool isKeyDown = false;
//
// FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
// PURPOSE: Processes messages for the main window.
//
// WM_COMMAND - process the application menu
// WM_PAINT - Paint the main window
// WM_DESTROY - post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	HDC hCompatibleDC;
	PAINTSTRUCT PaintStruct;
	HANDLE hBitmap, hOldBitmap;
	RECT Rect;
	BITMAP Bitmap;
	int wmId, wmEvent;
	HWND Bmove = NULL;
	HWND Bclear = NULL;
	HWND Bexit = NULL;
	HWND PaintField = NULL;
	PAINTSTRUCT ps;
	HDC hdc;
	WCHAR buffStr[21];
	WPARAM selIndex;
	RECT rects;
	GetWindowRect(hWnd, &rects);
	LONG widthd = rects.right - rects.left;
	LONG heightd = rects.bottom - rects.top;
	hBitmap = LoadImage(NULL, L"NEO.bmp", IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE);
	RECT rects2 = { 50 + 5,50 + 5,widthd - 45,heightd - 145 };

	switch (message)
	{
	case WM_CREATE:
		PaintField = CreateWindow(_T("MyPaintField"), _T(""), WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
			50, 50, widthd - 50, heightd - 150, hWnd, (HMENU)ID_BUTTON_PaintField, hInst, NULL);
		SetTimer(hWnd, 0, 10, NULL);
		Bmove = CreateWindow(_T("Button"), _T("MOVE"), WS_CHILD | WS_VISIBLE,
			widthd / 2 - 115, heightd - 130, 70, 40,
			hWnd, (HMENU)ID_BUTTON_MOVE, hInst, NULL);
		Bclear = CreateWindow(_T("Button"), _T("CLEAR"), WS_CHILD | WS_VISIBLE,
			widthd / 2 - 35, heightd - 130, 70, 40,
			hWnd, (HMENU)ID_BUTTON_CLEAR, hInst, NULL);
		Bexit = CreateWindow(_T("Button"), _T("EXIT"), WS_CHILD | WS_VISIBLE,
			widthd / 2 + 45, heightd - 130, 70, 40,
			hWnd, (HMENU)ID_BUTTON_EXIT, hInst, NULL);
		break;
	case WM_TIMER:
		//GetWindowRect(PaintField, &rects2);
		InvalidateRect(hWnd, &rects2, TRUE);
		break;
	case WM_KEYUP:
		switch (wParam)
		{
		case VK_SHIFT:
			message = WM_COMMAND;
			wmId = ID_BUTTON_MOVE;
			isKeyDown = true;
			break;
		case VK_CONTROL:
			for (int i = 0; i < ImagesCount; i++)
				mI[i].isNeedToMove = false;
			break;
		}
	case WM_COMMAND:
		if (!isKeyDown) {
			wmId = LOWORD(wParam);
		}
		isKeyDown = false;
		wmEvent = HIWORD(wParam);
		// Parse the menu selections:
		switch (wmId)
		{
		case IDM_ABOUT:
			DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
			break;
		case IDM_EXIT:
			DestroyWindow(hWnd);
			break;
		case ID_BUTTON_MOVE:
			//SendMessage(hWndListFrom, LB_ADDSTRING, 0, (LPARAM)_T("First"));
			//SendMessage(hWndListFrom, LB_ADDSTRING, 0, (LPARAM)_T("Second"));
			//SendMessage(hWndListFrom, LB_ADDSTRING, 0, (LPARAM)_T("Third"));
			for (int i = 0; i < ImagesCount; i++)
			{
				mI[i].isNeedToMove = true;
			}
			SetFocus(hWnd);
			break;
		case ID_BUTTON_CLEAR:
			for (int i = 0; i < ImagesCount; i++)
			{
				mI[i].~ImageMoving();
				mI[i] = ImageMoving();
				mI[i].isVisible = false;
			}
			ImagesCount = 0;
			SetFocus(hWnd);
			InvalidateRect(hWnd, &rects2, TRUE);
			MessageBox(NULL, L"Изображения удалены", L"Уведомление)", MB_ICONASTERISK | MB_OK);
			break;
		case ID_BUTTON_EXIT:
			switch ((int)MessageBox(NULL, L"Вы уверены, что хотите выйти?", L"Предупреждение",
				MB_ICONQUESTION | MB_YESNO))
			{
			case IDYES: DestroyWindow(hWnd); break;
			case IDNO: break;
			}
			//DestroyWindow(hWnd);
			break;
		case ID_BUTTON_PaintField:
			//GetWindowText(hWndEditAdd, buffStr, 20);
			//SendMessage(hWndListFrom, LB_ADDSTRING, 0, (LPARAM)buffStr);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
		break;
	case WM_LBUTTONUP:
	{
		if (ImagesCount < 1000)
		{
			int xPos = LOWORD(lParam);
			int yPos = HIWORD(lParam);
			RECT rect = { 0,0,0,0 };
			GetWindowRect(hWnd, &rect);
			LONG width = rect.right - rect.left;
			LONG height = rect.bottom - rect.top;
			if (xPos > 51 + 64 && xPos < width - 50 - 64 && yPos>51 + 64 && yPos < height - 150 - 64) {
				mI[ImagesCount] = ImageMoving(xPos - 64, yPos - 64, width - 50, height - 150, 128, 128);
				mI[ImagesCount].isVisible = true;
				ImagesCount++;
			}
			InvalidateRect(hWnd, &rects2, TRUE);
		}
	}
	break;
	case WM_CHAR:
	{
		TCHAR code = (TCHAR)wParam;
		if (nTextLen < 20)
		{
			text[nTextLen++] = code;
			RECT textRect = { 200, 200, 400, 250 };
			InvalidateRect(hWnd, &textRect, TRUE);
		}
	}
	break;
	case WM_PAINT:
	{
		hdc = BeginPaint(hWnd, &ps);
		RECT textRect = { 200, 200, 400, 250 };
		DrawText(hdc, text, nTextLen, &textRect, DT_CENTER);
		RECT rect;
		GetWindowRect(hWnd, &rect);
		LONG width = rect.right - rect.left;
		LONG height = rect.bottom - rect.top;
		HPEN pen = CreatePen(PS_SOLID, 5, RGB(0, 200, 0));
		HPEN oldPen = (HPEN)SelectObject(hdc, pen);
		MoveToEx(hdc, 50, 50, NULL);
		LineTo(hdc, width - 50, 50);
		LineTo(hdc, width - 50, height - 150);
		LineTo(hdc, 50, height - 150);
		LineTo(hdc, 50, 50);
		//GetObject(hBitmap, sizeof(BITMAP), &Bitmap);
		// hCompatibleDC = CreateCompatibleDC(hdc);
		// hOldBitmap = SelectObject(hCompatibleDC, hBitmap);
		GetClientRect(hWnd, &Rect);
		HINSTANCE sss = GetModuleHandle(0);
		//HICON hIcon = (HICON)LoadImage(hInst, L"NEO.ico", IMAGE_ICON, 32,32, LR_LOADTRANSPARENT);
		HICON hIcon = (HICON)LoadImage(NULL, L"rocet.ico", IMAGE_ICON, 128, 128, LR_LOADFROMFILE);
		HICON hIcon2 = (HICON)LoadImage(NULL, L"rocket_back.ico", IMAGE_ICON, 128, 128, LR_LOADFROMFILE);
		int x = 0;
		int y = 0;
		for (int i = 0; i < ImagesCount; i++)
		{
			if (mI[i].isVisible) {
				mI[i].getNextPos(&x, &y);
				if(!mI[i].isMirror)
					DrawIconEx(hdc, x, y, hIcon, 128, 128, 0, NULL, DI_NORMAL);
				else
					DrawIconEx(hdc, x, y, hIcon2, 128, 128, 0, NULL, DI_NORMAL);
			}
		}
		DestroyIcon(hIcon);
		SelectObject(hdc, oldPen);
		DeleteObject(pen);
		EndPaint(hWnd, &ps);
	}
	break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	default:
		DeleteObject(hBitmap);
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	DeleteObject(hBitmap);
	return 0;
}
// Message handler for about box.
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