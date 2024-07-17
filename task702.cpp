#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>

using namespace std;
// Read file content into a vector of strings

vector<std::string> readFile(const string& filePath) {
    std::ifstream file(filePath);
    vector<std::string> lines;
    string line;

    if (file.is_open()) {
        while (getline(file, line)) {
            lines.push_back(line);
        }
        file.close();
    } else {
        cerr << "Unable to open file: " << filePath << endl;
    }

    return lines;
}

// find the difference and create commit message
string Createmessage(const vector<string>& original, const vector<string>& modified) {
    std::ostringstream commitMessage;
    int addedCount = 0, removedCount = 0, modifiedCount = 0;

    size_t origSize = original.size();
    size_t modSize = modified.size();
    size_t maxSize = max(origSize, modSize);

    for (size_t i = 0; i < maxSize; ++i) {
        if (i >= origSize) {
            // Line added
            addedCount++;
        } else if (i >= modSize) {
            // Line removed
            removedCount++;
        } else if (original[i] != modified[i]) {
            // Line modified
            modifiedCount++;
        }
    }

    commitMessage << "Changes made:\n";
    if (addedCount > 0) {
        commitMessage << "- " << addedCount << " line(s) added\n";
    }
    if (removedCount > 0) {
        commitMessage << "- " << removedCount << " line(s) removed\n";
    }
    if (modifiedCount > 0) {
        commitMessage << "- " << modifiedCount << " line(s) modified\n";
    }

    return commitMessage.str();
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        cerr << "Usage : " << argv[0] << " <originalFile> <modifiedFile>";
        cout<<endl;
        return 1;
    }

    string originalFilePath = argv[1];
    string modifiedFilePath = argv[2];

    // Read files
    vector<string> originalContent = readFile(originalFilePath);
    vector<string> modifiedContent = readFile(modifiedFilePath);

    // Generate commit message
    string commitMessage = Createmessage(originalContent, modifiedContent);

    // Output commit message
    cout << commitMessage << endl;

    return 0;
}

/* 
sample usage 
input -> ./task702 task414.sh task414f.sh 
output-> Changes made:
- 2 line(s) removed
- 52 line(s) modified

*/