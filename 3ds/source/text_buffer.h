#pragma once
#include <string>
#include <vector>

// Width in characters at which soft word-wrap occurs.
// The system font is proportional; wide chars at SCALE=0.65 average ~10px,
// giving ~38 chars across the 380px usable width of the top screen.
static const int TEXT_BUFFER_WIDTH = 48;

class TextBuffer {
public:
    TextBuffer() {}

    void append(char c) {
        if (c == '\b') {
            backspace();
        } else if (c == '\n') {
            content_ += '\n';
        } else {
            content_ += c;
        }
    }

    void backspace() {
        if (!content_.empty()) {
            content_.pop_back();
        }
    }

    // Returns lines wrapped at TEXT_BUFFER_WIDTH, suitable for rendering.
    std::vector<std::string> getLines() const {
        std::vector<std::string> result;
        // Split at newlines first
        std::vector<std::string> paragraphs;
        std::string current;
        for (char c : content_) {
            if (c == '\n') {
                paragraphs.push_back(current);
                current.clear();
            } else {
                current += c;
            }
        }
        paragraphs.push_back(current);

        // Word-wrap each paragraph at TEXT_BUFFER_WIDTH (hard wrap)
        for (const std::string& para : paragraphs) {
            size_t pos = 0;
            while (pos < para.size()) {
                result.push_back(para.substr(pos, TEXT_BUFFER_WIDTH));
                pos += TEXT_BUFFER_WIDTH;
            }
            if (para.empty()) {
                result.push_back("");
            }
        }
        return result;
    }

    void loadRaw(const std::string& text) {
        content_.clear();
        for (char c : text) {
            if ((c >= 32 && c <= 126) || c == '\n') content_ += c;
        }
    }

    std::string getContent() const {
        return content_;
    }

private:
    std::string content_;
};
