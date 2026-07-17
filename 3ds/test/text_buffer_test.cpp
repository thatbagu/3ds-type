#include <iostream>
#include <string>
#include <vector>
#include "text_buffer.h"

int test_word_wrap() {
    TextBuffer buf;
    for (int i = 0; i < 55; i++) {
        buf.append('a');
    }
    std::vector<std::string> lines = buf.getLines();
    if (lines.size() != 2) {
        std::cerr << "word-wrap FAIL: expected 2 lines, got " << lines.size() << "\n";
        return 1;
    }
    if (lines[0].size() != 50) {
        std::cerr << "word-wrap FAIL: expected line[0] length 50, got " << lines[0].size() << "\n";
        return 1;
    }
    if (lines[1].size() != 5) {
        std::cerr << "word-wrap FAIL: expected line[1] length 5, got " << lines[1].size() << "\n";
        return 1;
    }
    std::cout << "word-wrap PASS\n";
    return 0;
}

int test_backspace() {
    TextBuffer buf;
    for (char c : std::string("hello")) {
        buf.append(c);
    }
    buf.backspace();
    buf.backspace();
    std::string content = buf.getContent();
    if (content != "hel") {
        std::cerr << "backspace FAIL: expected \"hel\", got \"" << content << "\"\n";
        return 1;
    }
    std::cout << "backspace PASS\n";
    return 0;
}

int test_newline() {
    TextBuffer buf;
    for (char c : std::string("line1\nline2")) {
        buf.append(c);
    }
    std::vector<std::string> lines = buf.getLines();
    if (lines.size() != 2) {
        std::cerr << "newline FAIL: expected 2 lines, got " << lines.size() << "\n";
        return 1;
    }
    if (lines[0] != "line1") {
        std::cerr << "newline FAIL: expected lines[0]=\"line1\", got \"" << lines[0] << "\"\n";
        return 1;
    }
    if (lines[1] != "line2") {
        std::cerr << "newline FAIL: expected lines[1]=\"line2\", got \"" << lines[1] << "\"\n";
        return 1;
    }
    std::cout << "newline PASS\n";
    return 0;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: text_buffer_test <word-wrap|backspace|newline>\n";
        return 1;
    }
    std::string test = argv[1];
    if (test == "word-wrap") {
        return test_word_wrap();
    } else if (test == "backspace") {
        return test_backspace();
    } else if (test == "newline") {
        return test_newline();
    } else {
        std::cerr << "Unknown test: " << test << "\n";
        return 1;
    }
}
