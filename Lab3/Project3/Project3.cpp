#include <iostream>
using namespace std;

struct Elem
{
	string data;
	Elem* next, * prev;
};

class List
{
	Elem* Head, * Tail;
	int Count;

public:

	List();
	List(const List&);
	~List();

	int GetCount();
	Elem* GetElem(int);

	void DelAll();
	void Del(int pos = 0);
	void Insert(string n, int pos = 0);
	void AddToTail(string n);
	void AddToHead(string n);
	void Print();
	void Print(int pos);
};

List::List()
{
	Head = Tail = NULL;
	Count = 0;
}

List::List(const List& L)
{
	Head = Tail = NULL;
	Count = 0;
	Elem* temp = L.Head;
	while (temp != 0)
	{
		AddToTail(temp->data);
		temp = temp->next;
	}
}

List::~List()
{
	DelAll();
}

void List::AddToHead(string n)
{
	Elem* temp = new Elem;
	temp->prev = 0;
	temp->data = n;
	temp->next = Head;
	if (Head != 0)
		Head->prev = temp;
	if (Count == 0)
		Head = Tail = temp;
	else
		Head = temp;
	Count++;
}

void List::AddToTail(string n)
{
	Elem* temp = new Elem;
	temp->next = 0;
	temp->data = n;
	temp->prev = Tail;
	if (Tail != 0)
		Tail->next = temp;
	if (Count == 0)
		Head = Tail = temp;
	else
		Tail = temp;
	Count++;
}

void List::Insert(string data, int pos)
{
	if (pos < 1 || pos > Count + 1)
	{
		cout << "Wrong position!\n";
		return;
	}

	if (pos == Count + 1)
	{
		AddToTail(data);
		return;
	}
	else if (pos == 1)
	{
		AddToHead(data);
		return;
	}

	int i = 1;
	string new_data = data;
	Elem* Ins = Head;
	while (i < pos)
	{
		Ins = Ins->next;
		i++;
	}

	Elem* PrevIns = Ins->prev;

	Elem* temp = new Elem;
	temp->data = data;
	if (PrevIns != 0 && Count != 1)
		PrevIns->next = temp;
	temp->next = Ins;
	temp->prev = PrevIns;
	Ins->prev = temp;
	Count++;
}

void List::Del(int pos)
{
	if (pos < 1 || pos > Count)
	{
		cout << "Wrong position!\n";
		return;
	}

	int i = 1;
	Elem* Del = Head;
	while (i < pos)
	{
		Del = Del->next;
		i++;
	}

	Elem* PrevDel = Del->prev;
	Elem* AfterDel = Del->next;

	if (PrevDel != 0 && Count != 1)
		PrevDel->next = AfterDel;
	if (AfterDel != 0 && Count != 1)
		AfterDel->prev = PrevDel;

	if (pos == 1)
		Head = AfterDel;
	if (pos == Count)
		Tail = PrevDel;

	delete Del;
	Count--;
}

void List::Print(int pos)
{
	if (pos < 1 || pos > Count)
	{
		cout << "Wrong position!\n";
		return;
	}

	Elem* temp;
	if (pos <= Count / 2)
	{
		temp = Head;
		int i = 1;

		while (i < pos)
		{
			temp = temp->next;
			i++;
		}
	}
	else
	{
		temp = Tail;
		int i = 1;

		while (i <= Count - pos)
		{
			temp = temp->prev;
			i++;
		}
	}
	cout << pos << " element: ";
	cout << temp->data << endl;
}

void List::Print()
{
	if (Count != 0)
	{
		Elem* temp = Head;
		while (temp != nullptr)
		{
			cout << temp->data << " ";
			temp = temp->next;
		}
	}
}

void List::DelAll()
{
	while (Count != 0)
		Del(1);
}

int List::GetCount()
{
	return Count;
}

Elem* List::GetElem(int pos)
{
	Elem* temp = Head;
	if (pos < 1 || pos > Count)
	{
		cout << "Incorrect position !!!\n";
		return 0;
	}
	int i = 1;
	while (i < pos && temp != 0)
	{
		temp = temp->next;
		i++;
	}
	if (temp == 0)
		return 0;
	else
		return temp;
}

void main()
{
	List list;
	list.AddToHead("1");
	list.AddToHead("2");
	list.AddToHead("4");
	list.AddToHead("5");
	list.AddToHead("6");
	cout << "List L:\n";
	list.Print();
	cout << endl;

	list.AddToTail("Tail");
	cout << "List after AddToTail: \n";
	list.Print();
	cout << endl;

	list.Insert("3", 4);
	cout << "List after Insert:\n";
	list.Print();
	cout << endl;


	list.Del(3);
	cout << "List after Del: \n";
	list.Print();

	cout << "\n";
	list.Print(3);

	cout << "Lenght List: ";
	cout<<list.GetCount();

	cout << "\nDelete all\n";
	list.DelAll();
	list.Print();
}