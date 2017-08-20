/**
 * @fileOverview This implements the editor.
 */

// File extension string to file mode string mapping.
EXT_TYPE_MAP = {
    c: 'text/x-csrc',
    cpp: 'text/x-c++src',
    css: 'css',
    cxx: 'text/x-c++src',
    go: 'go',
    html: 'htmlmixed',
    java: 'text/x-java',
    javascript: 'javascript',
    js: 'javascript',
    json: 'application/json',
    lua: 'lua',
    md: 'markdown',
    o: 'octave',
    octave: 'octave',
    r: 'r',
    sh: 'shell',
    py: 'python',
    xml: 'xml'
};

SAVE_FILE_INTERVAL_SEC = 1; // Delay for each saving event.
UPDATE_MARKDOWN_INTERVAL_SEC = 0.5; // Delay for each update Markdown event.

/**
 * Wraps a CodeMirror editor with server-client communication.
 * @param {type} cm
 * @returns {undefined}
 */
function RemoteFileEditor(cm) {
    // The most current editor content, use this instead editor.getValue() to save function calls.
    this.currentContent = '';
    this.editor = cm; // This is the editor.
    this.editorFontSize = 14; // Default font size.
    this.fileOriginalContent = null;
    this.filePath = '';
    this.fileType = '';
    this.initialLineNumber = 0; // Jumps to this line after the initial loading.
    this.mode = null; // If set, overwrites fileType.
    this.ruler = null; // The value for the ruler.
    this.theme = 'monokai';
    this.serverAddress = '/'; // The RemoteFileEditor server.

    this.CURSOR_MARKER_STRING = 'CURSOR-IS-PLACED-AT-NEXT-LINE';

    _this = this;

    /**
    * Checks if the current version is saved correctly, and saves if not.
    */
    this.checkSaveStatus = function() {
        this.syncUpSaveButtonStatus();
        if (this.isModified()) {
            this.saveBuffered.call();
        }
    };

    /**
    * Guesses the type of a file from its name.
    * @param {type} filePath The relative path of a file.
    * @returns {guessFileType.fileNameSegments}
    */
    this.guessFileType = function(filePath) {
        var fileNameSegments = filePath.split('.');
        var ext = fileNameSegments[fileNameSegments.length - 1];
        if (ext in EXT_TYPE_MAP) {
            return EXT_TYPE_MAP[ext];
        } else {
            return 'text';
        }
    };

    /**
    * Returns if the content has been modified.
    *
    * Uses the stored text and editorValue for decision.
    * @returns {boolean}
    */
    this.isModified = function() {
        if (this.fileOriginalContent !== null &&
            this.fileOriginalContent !== this.currentContent) {
            return true;
        } else {
            return false;
        }
    };

    /**
    * Loads file content from this.filePath to the editor.
    */
    this.loadFileContent = function() {
        var saveThis = this;
        $.get(this.serverAddress + this.filePath).always(function(response) {
            var content;
            if (response.responseText) {
                content = response.responseText;
            } else {
                content = response;
            }
            saveThis.editor.setValue(content);
            saveThis.editor.refresh();
            saveThis.fileOriginalContent = content;
            // Jumps to the specified line number.
            saveThis.editor.setCursor(100000000000);
            saveThis.editor.setCursor(saveThis.initialLineNumber - 1);

            saveThis.updateMarkdown(content);
        });
    };

    this.onEditorChange = function() {
        this.currentContent = this.editor.getValue();
        this.checkSaveStatus();
    };

    /**
    * Saves the file content on server.
    */
    this.save = function() {
        if (!this.isModified()) {
            return; // Nothing needs to be save now.
        }

        // Save content.
        var newContent = this.currentContent;
        var parameters = 'filepath=' + this.filePath +
            '&' + 'filecontent=' + encodeURIComponent(newContent);
        var saveThis = this;
        $.post(this.serverAddress + 'save', parameters).done(function() {
            saveThis.fileOriginalContent = newContent;
            // Check to see if another save is needed. This is necessary because
            // if a change is made during the save (POST) action, then
            // fileOriginalContent has not changed yet, so that isModified
            // triggered during another change action is comparing to the
            // un-updated value, which may be wrong.
            saveThis.checkSaveStatus();
        }).fail(function() {
            alert('File cannot be saved!');
        });
    };

    // Buffers call to this.save.
    this.saveBuffered = new CallBuffer(function() {
        _this.save();
    }, SAVE_FILE_INTERVAL_SEC);

    this.syncUpSaveButtonStatus = function() {
        if (this.isModified()) {
            $('#saveIcon').attr('src', '/editor/edit_icon.png');
        } else {
            $('#saveIcon').attr('src', '/editor/save_icon.png');
        }
    };

    /**
     * Updates with the rendered markdown.
     */
    this.updateMarkdown = function() {
        if (this.fileType !== 'markdown') {
            return;
        }
        var content = this.currentContent;
        var contentBreakout = content.split('\n');
        contentBreakout.splice(this.editor.getCursor().line, 0, '\n' + this.CURSOR_MARKER_STRING + '\n');
        var contentMergedBack = contentBreakout.join('\n');
        var contentRendered = marked(contentMergedBack);
        contentRendered = contentRendered.replace(this.CURSOR_MARKER_STRING,
            '<img id="cursor_marker" src="/editor/locator.png" alt="CURSOR NEXT LINE">');
        $('#markdownDisplay').html(contentRendered);
        $('#cursor_marker').get(0).scrollIntoView();
    };

    // Buffers calls to this.updateMarkdown.
    this.updateMarkdownBuffered = new CallBuffer(function() {
        _this.updateMarkdown();
    }, UPDATE_MARKDOWN_INTERVAL_SEC);

    this.syncUpTitle = function() {
        $('#title').text('[' + this.fileType + '] ' + this.filePath);
    };

    this.setOptions = function() {
        // Decide mode and filetype.
        if (this.mode !== null) {
            this.fileType = this.mode;
        } else {
            this.fileType = this.guessFileType(this.filePath);
        }
        this.syncUpTitle();

        // Set mode, theme, font.
        this.editor.setOption('mode', this.fileType ? this.fileType : 'text');
        // var default_theme = this.fileType === 'text' || this.fileType === 'markdown' ? 'solarized' : 'twilight';
        var default_theme = 'solarized';
        this.editor.setOption('theme', this.theme ? this.theme : default_theme);
        $('.CodeMirror').css('font-size', this.fontSize ? this.fontSize : 14);

        // Sets to use sublime key binding.
        this.editor.setOption('keyMap', 'sublime');

        // Various improvements.
        this.editor.setOption('autoCloseBrackets', true);
        this.editor.setOption('autoCloseTags', true);
        this.editor.setOption('continuousComments', true);
        this.editor.setOption('lineNumbers', true);
        this.editor.setOption('lineWrapping', true);
        this.editor.setOption('matchBrackets', true);
        this.editor.setOption('scrollbarStyle', 'overlay');

        // Decides ruler.
        if (this.fileType === 'text' || this.fileType === 'markdown') {
        } else if (this.ruler) {
            this.editor.setOption('rulers', [parseInt(this.ruler)]);
        } else {
            this.editor.setOption('rulers', [80, 100]);
        }

        // Replaces all tabs by spaces.
        this.editor.setOption('extraKeys', {
            Tab: function(cm) {
                if (cm.getSelection() === '') {
                    var cur = cm.getCursor();
                    var textBefore = cm.getLine(cur.line).slice(0, cur.ch);
                    if (textBefore.trim() === '') {
                        // Cursor at the beginning of a line, indent.
                        var spaces = Array(cm.getOption('indentUnit') + 1).join(' ');
                        cm.replaceSelection(spaces);
                    } else {
                        cm.showHint();
                    }
                } else {
                    cm.indentSelection();
                }
            }
        });

        // No smart indent --- it's horrible.
        this.editor.setOption('smartIndent', false);

        // Editor size.
        if (this.fileType === 'markdown') {
            var sep = '40%';
            var $markdownDisplay = $('#markdownDisplay');
            var remain = 'calc(100% - ' + sep + ' - ' +
                $markdownDisplay.css('padding-left') + ' - ' +
                $markdownDisplay.css('padding-right') + ')';
            $('#editorContainer').css('width', sep);
            $('#markdownDisplay').css('width', remain).css('left', sep).show();

            // Setup renderer.
            marked.setOptions({
                renderer: new marked.Renderer(),
                smartypants: true
            });

            // Setup listener to the cursor activity.
            var saveThis = this;
            this.editor.on('cursorActivity', function() {
                saveThis.updateMarkdownBuffered.call();
            });
        } else {
            $('#editorContainer').css('width', '100%');
            $('#markdownDisplay').css('width', '0%').hide();
        }
        this.editor.setSize('100%', '100%');
    };

    this.startMe = function() {
        var saveThis = this;
        this.loadFileContent();
        this.editor.on('change', function() {
            saveThis.onEditorChange();
        });
    };
};



$(document).ready(function() {
    rfe = new RemoteFileEditor(CodeMirror($('#editorContainer')[0]));

    rfe.editorFontSize = gup('fontsize');
    rfe.filePath = gup('file');
    rfe.initialLineNumber = gup('linenumber');
    rfe.mode = gup('mode');
    rfe.ruler = gup('ruler');
    rfe.theme = gup('theme');

    rfe.setOptions();
    rfe.startMe();
});
