using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace SP_LAB_12
{
    public partial class Form1 : Form
    {
        static int x = 0;

        AutoResetEvent myEvent = new AutoResetEvent(true);
        object myObj = new object();

        public Form1()
        {
            InitializeComponent();
        }

        public void SyncEvent()
        {
            myEvent.WaitOne();
            x = 1;
            for (int i = 1; i < 9; i++)
            {
                textBox1.Text = String.Format("{0}: {1}", Thread.CurrentThread.Name, x);
                x++;
                Thread.Sleep(100);
            }
            myEvent.Set();
        }

        public void SyncLock()
        {
            lock (myObj)
            {
                x = 1;
                for (int i = 1; i < 9; i++)
                {
                    textBox2.Text = String.Format("{0}: {1}", Thread.CurrentThread.Name, x);
                    x++;
                    Thread.Sleep(100);
                }
            }
        }

        public void startThreads(object arr)
        {
            var tuple = (Tuple<ThreadStart, Button>)arr;
            ThreadStart action = tuple.Item1;
            Thread[] myThreads = new Thread[5];
            for (int i = 0; i < myThreads.Length; i++)
            {
                myThreads[i] = new Thread(action);
                myThreads[i].Name = $"thread[{i}]";
                myThreads[i].Start();
            }
            for (int i = 0; i < myThreads.Length; i++)
                myThreads[i].Join();

            tuple.Item2.Enabled = true;
        }

        private void button1_Click(object sender, EventArgs e)
        {
            button1.Enabled = false;
            Thread myThread = new Thread(startThreads);
            myThread.Name = "SyncEvent";
            myThread.Start(new Tuple<ThreadStart, Button>(new ThreadStart(SyncEvent), button1));
        }

        private void button2_Click(object sender, EventArgs e)
        {
            button2.Enabled = false;
            Thread myThread = new Thread(startThreads);
            myThread.Name = "SyncLock";
            myThread.Start(new Tuple<ThreadStart, Button>(new ThreadStart(SyncLock), button2));
        }
    }
}
