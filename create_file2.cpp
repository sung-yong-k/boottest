#include <fstream>
#include <string>

void tryCreate(const std::string& path, const std::string& content)
{
    std::ofstream file(path);
    if (!file.is_open())
        return; // Path or drive doesn't exist → ignore

    file << content;
    file.close();
}

int main()
{
    tryCreate("C:\\test2.txt", "testC");
    tryCreate("X:\\test2.txt", "testX");
    tryCreate("D:\\test2.txt", "testD");
    tryCreate("G:\\test2.txt", "testG");

    return 0;
}
