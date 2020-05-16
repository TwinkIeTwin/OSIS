// Lab2.cpp : Определяет точку входа для приложения.
//

#include "stdafx.h"
#include "Lab2.h"

#define MAX_LOADSTRING 100

// Глобальные переменные:
HINSTANCE hInst;                                // текущий экземпляр
WCHAR szTitle[MAX_LOADSTRING];                  // Текст строки заголовка
WCHAR szWindowClass[MAX_LOADSTRING];            // имя класса главного окна
HWND hAdd;
HWND hClear;
HWND hToRight;
HWND hDelete;
HWND hListBox1;
HWND hListBox2;
HWND hEdit;

// Отправить объявления функций, включенных в этот модуль кода:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    About(HWND, UINT, WPARAM, LPARAM);

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // TODO: Разместите код здесь.

    // Инициализация глобальных строк
    LoadStringW(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(hInstance, IDC_LAB2, szWindowClass, MAX_LOADSTRING);
    MyRegisterClass(hInstance);

    // Выполнить инициализацию приложения:
    if (!InitInstance (hInstance, nCmdShow))
    {
        return FALSE;
    }

    HACCEL hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_LAB2));

    MSG msg;

    // Цикл основного сообщения:
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return (int) msg.wParam;
}



//
//  ФУНКЦИЯ: MyRegisterClass()
//
//  ЦЕЛЬ: Регистрирует класс окна.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

    wcex.style          = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc    = WndProc;
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = hInstance;
    wcex.hIcon          = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_LAB2));
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
    wcex.lpszMenuName   = MAKEINTRESOURCEW(IDC_LAB2);
    wcex.lpszClassName  = szWindowClass;
    wcex.hIconSm        = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

    return RegisterClassExW(&wcex);
}

//
//   ФУНКЦИЯ: InitInstance(HINSTANCE, int)
//
//   ЦЕЛЬ: Сохраняет маркер экземпляра и создает главное окно
//
//   КОММЕНТАРИИ:
//
//        В этой функции маркер экземпляра сохраняется в глобальной переменной, а также
//        создается и выводится главное окно программы.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   hInst = hInstance; // Сохранить маркер экземпляра в глобальной переменной

   HWND hWnd = CreateWindowW(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, nullptr, nullptr, hInstance, nullptr);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

//
//  ФУНКЦИЯ: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  ЦЕЛЬ: Обрабатывает сообщения в главном окне.
//
//  WM_COMMAND  - обработать меню приложения
//  WM_PAINT    - Отрисовка главного окна
//  WM_DESTROY  - отправить сообщение о выходе и вернуться
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
	case WM_CREATE:                      //Создание интерфейса
	{		
		hAdd = CreateWindow(L"BUTTON", L"Add", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
			10, 10, 80, 40, hWnd, HMENU(MY_BUTTON_ADD), hInst, NULL);   

		hClear = CreateWindow(L"BUTTON", L"Clear", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
			10, 60, 80, 40, hWnd, HMENU(MY_BUTTON_CLEAR), hInst, NULL);

		hToRight = CreateWindow(L"BUTTON", L"ToRight", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
			10, 110, 80, 40, hWnd, HMENU(MY_BUTTON_TORIGHT), hInst, NULL);

		hDelete = CreateWindow(L"BUTTON", L"Delete", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
			10, 160, 80, 40, hWnd, HMENU(MY_BUTTON_DELETE), hInst, NULL);
		
		hListBox1 = CreateWindow(L"LISTBOX", NULL, WS_CHILD | WS_VISIBLE | LBS_STANDARD,
			130, 10, 350, 400, hWnd, HMENU(MY_LISTBOX1), hInst, NULL);

		hListBox2 = CreateWindow(L"LISTBOX", NULL, WS_CHILD | WS_VISIBLE | LBS_STANDARD,
			490, 10, 350, 400, hWnd, HMENU(MY_LISTBOX2), hInst, NULL);

		hEdit = CreateWindow(L"EDIT", NULL, WS_CHILD | WS_VISIBLE | WS_BORDER,  // HWND
			130, 410, 710, 20, hWnd, HMENU(MY_EDIT), hInst, NULL);
		break;
	}
    case WM_COMMAND:
        {
            int wmId = LOWORD(wParam);
            // Разобрать выбор в меню:
			int size;
			TCHAR text[1024];
            switch (wmId)
            {
			case MY_BUTTON_ADD:
				GetWindowText(hEdit, text, sizeof(text));
				if (SendMessage(hListBox1, LB_FINDSTRINGEXACT, -1, (LPARAM)text) == LB_ERR && text[0] != '\0')
				{
					SendMessage(hListBox1, LB_ADDSTRING, NULL, (LPARAM)text);
				}
			    break;
			case MY_BUTTON_CLEAR:
				size = SendMessage(hListBox1, LB_GETCOUNT, NULL, NULL);
				while (size > 0)
				{
					size = SendMessage(hListBox1, LB_DELETESTRING, 0, NULL);
				}
				size = SendMessage(hListBox2, LB_GETCOUNT, NULL, NULL);
				while (size > 0)
				{
					size = SendMessage(hListBox2, LB_DELETESTRING, 0, NULL);
				}
				break;
			case MY_BUTTON_DELETE:
				size = SendMessage(hListBox1, LB_GETCURSEL, NULL, NULL);
				SendMessage(hListBox1, LB_DELETESTRING, size, NULL);
				size = SendMessage(hListBox2, LB_GETCURSEL, NULL, NULL);
				SendMessage(hListBox2, LB_DELETESTRING, size, NULL);
				break;
			case MY_BUTTON_TORIGHT:
				size = SendMessage(hListBox1, LB_GETCURSEL, NULL, NULL);
				SendMessage(hListBox1, LB_GETTEXT, size, (LPARAM)text);
				if (SendMessage(hListBox2, LB_FINDSTRINGEXACT, -1, (LPARAM)text) == LB_ERR)
				{
					SendMessage(hListBox2, LB_ADDSTRING, NULL, (LPARAM)text);
				}
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
        }
        break;
    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hWnd, &ps);
            // TODO: Добавьте сюда любой код прорисовки, использующий HDC...
            EndPaint(hWnd, &ps);
        }
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

// Обработчик сообщений для окна "О программе".
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


