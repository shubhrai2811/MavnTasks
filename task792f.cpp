#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <stdexcept>
#include <sstream>
#include <array>
#include <unistd.h>  

using namespace std;

// Custom exception for file handling errors
class CommandException : public runtime_error {
public:
    explicit CommandException(const string &message) : runtime_error(message) {}
};

// Function to run a system command and capture its output
string runCommand(const string &command) {
    array<char, 128> buffer;
    string result;
    FILE *mypipe = popen(command.c_str(), "r");
    if (!mypipe) {
        throw CommandException("Error: Unable to execute command.");
    }
    while (fgets(buffer.data(), buffer.size(), mypipe) != nullptr) {
        result += buffer.data();
    }
    if (pclose(mypipe) != 0) {
        throw CommandException("Error: Command execution failed.");
    }
    return result;
}

// Function to parse diff lines and extract meaningful changes
vector<string> extractChanges(const vector<string> &diffLines) {
    vector<string> changes;
    for (auto &lines : diffLines) {
        if (!lines.empty() and (lines[0] == '+' || lines[0] == '-')) {
            changes.push_back(lines);
        }
    }
    return changes;
}

// Function to generate a commit message based on extracted changes
string generateCommitMessage(const vector<string> &changes) {
    ostringstream commitMessage;
    commitMessage << "Summary of changes:" << endl << endl;

    commitMessage << "Added lines:" << endl;
    for (const auto &change : changes) {
        if (change[0] == '+') {
            commitMessage << change.substr(1) << endl;
        }
    }

    commitMessage << endl << "Removed lines:" << endl;
    for (const auto &change : changes) {
        if (change[0] == '-') {
            commitMessage << change.substr(1) << endl;
        }
    }

    return commitMessage.str();
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        cerr << "Usage: " 
        << argv[0] << " <directory>" 
        << endl;
        exit(1);;
    }

    string directory = argv[1];

    try {
        // Change to the specified directory
        if (chdir(directory.c_str()) != 0) {
            throw CommandException("Error: Unable to cd to directory " + directory);
        }

        // Run the git diff command and capture the output
        string diffOutput = runCommand("git diff HEAD");

        // Split the diff output into lines
        istringstream diffStream(diffOutput);
        string line;
        vector<string> diffLines;
        while (getline(diffStream, line)) {
            diffLines.push_back(line);
        }

        // Extract changes and generate the commit message
        vector<string> changes = extractChanges(diffLines);
        string commitMessage = generateCommitMessage(changes);

        cout << commitMessage << endl;

    } catch (const CommandException &e) {
        cerr << e.what() << endl;
        exit(1);
    } catch (exception &err) {
        cerr << "Error : " 
        << err.what() << endl;
        exit(1);
    }

    return 0;
}
