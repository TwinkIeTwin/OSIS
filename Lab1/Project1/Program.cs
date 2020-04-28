using System;
using System.Collections.Generic;
using System.IO;

namespace Project1
{
    class Program
    {
        static void WriteResult(string resultFile, List<string> all_files)
        {
            List<string> resultText = new List<string>();
            foreach (string file in all_files)
            {
                resultText.AddRange(File.ReadAllLines(file));

            }
            File.WriteAllLines(resultFile, resultText);
        }

        static string[] SearchFiles(string path, string pattern)
        {
            string[] resultSearch = Directory.GetFiles(path, pattern, SearchOption.AllDirectories);
            return resultSearch;
        }

        static List<string> FoundFiles(string[] res, string path_for_search, string fileName)
        {
            string pattern = "*" + fileName + "*" + "*.txt";
            string print_res = "On disk " + path_for_search + " founded :\n";
            string[] b = Directory.GetFiles(path_for_search, pattern);
            List<string> all_files = new List<string>();
            foreach (string a in b)
            {
                print_res += a + "\n";
                all_files.Add(a);
            }

            foreach (string folder in res)
            {
                try
                {
                    string[] files = SearchFiles(folder, pattern);
                    foreach (string file in files)
                    {
                        print_res += file + "\n";
                        all_files.Add(file);
                    }
                }
                catch
                {

                    Console.WriteLine("Error access: " + folder);
                }
            }
            Console.WriteLine(print_res);
            return all_files;
        }
        static void Main(string[] args)
        {
            var read = Console.ReadLine();
            Console.WriteLine(@"Start searching on D:\\");
            string path_for_search = @"D:\\Osis";
            string resultFile = "C:\\result.txt";
            string[] res = Directory.GetDirectories(path_for_search);
            List<string> all_files = FoundFiles(res, path_for_search, read);
            WriteResult(resultFile, all_files);

        }
    }
}
