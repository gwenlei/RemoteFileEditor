/**
 * @fileOverview This implements the editor.
 */

// File extension string to file mode string mapping.
EXT_TYPE_MAP = {
    c: 'c',
    cpp: 'c++',
    css: 'css',
    cxx: 'c++',
    go: 'go',
    html: 'html',
    java: 'java',
    javascript: 'javascript',
    js: 'javascript',
    json: 'json',
    lua: 'lua',
    md: 'markdown',
    o: 'octave',
    octave: 'octave',
    r: 'r',
    sh: 'shell',
    py: 'python',
    xml: 'xml'
};

SAVE_FILE_INTERVAL_SEC = 1;

/**
 * Wraps a CodeMirror editor with server-client communication.
 * @param {type} cm
 * @returns {undefined}
 */
function RemoteFileEditor(ace_editor) {
    this.editor = ace_editor; // This is the editor.
    this.editorFontSize = null; // Default font size.
    this.fileOriginalContent = null;
    this.filePath = null;
    this.fileType = null;
    this.initialLineNumber = 0; // Jumps to this line after the initial loading.
    this.mode = null; // If set, overwrites fileType.
    this.ruler = null; // The value for the ruler.
    this.theme = null;
    this.saveFileTimer = null; // To buffer file change event into fewer saves.
    this.serverAddress = '/'; // The RemoteFileEditor server.
    
    /**
    * Checks if the current version is saved correctly, and saves if not.
    */
    this.checkSaveStatus = function() {
        this.syncUpSaveButtonStatus();
        if (this.isModified()) {
            this.setSaveFileTimer();
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
            this.fileOriginalContent !== this.editor.getSession().getValue()) {
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
            saveThis.editor.getSession().setValue(content);
//            saveThis.editor.refresh();
            saveThis.fileOriginalContent = content;
            // Jumps to the specified line number.
            saveThis.editor.resize(true);
            saveThis.editor.scrollToLine(50, true, true, function () {});
            saveThis.editor.gotoLine(50, 10, true);
//            saveThis.editor.setCursor(100000000000);
//            saveThis.editor.setCursor(saveThis.initialLineNumber - 1);
        });
    };
    
    this.onEditorChange = function() {
       this.checkSaveStatus();
    };
    
    /**
    * Saves the file content on server.
    */
    this.save = function() {
        if (!this.isModified()) {
            return; // Nothing needs to be save now.
        }

        var newContent = this.editor.getValue();
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
    
    /**
    * Sets a save file timer.
    */
    this.setSaveFileTimer = function() {
        if (this.saveFileTimer) {
            clearTimeout(this.saveFileTimer);
        }
        var saveThis = this;
        this.saveFileTimer = setTimeout(function() {
            saveThis.save();
        }, SAVE_FILE_INTERVAL_SEC * 1000);
    };
    
    this.syncUpSaveButtonStatus = function() {
        if (this.isModified()) {
            $('#saveIcon').attr('src', '/editor/edit_icon.png');
        } else {
            $('#saveIcon').attr('src', '/editor/save_icon.png');
        }
    };
    
    this.syncUpTitle = function() {
        $('#title').text('[' + this.fileType + '] ' + this.filePath);
    };
    
    this.setOptions = function() {       
        // Enables auto complete.
        this.editor.setOptions({
            enableBasicAutocompletion: true,
            enableSnippets: true,
            enableLiveAutocompletion: true
        });
    
        // Sets file type and path, syncs title.
        this.filePath = this.filePath ? this.filePath : '';
        if (this.mode) {
            this.fileType = this.mode;
        } else {
            this.fileType = this.guessFileType(this.filePath);
        }
        this.syncUpTitle();

        
        // Sets mode, theme, font.
        this.editor.session.setMode('ace/mode/' + (this.fileType ? this.fileType : 'text'));
        this.editor.setTheme('ace/theme/' + (this.theme ? this.theme : 'solarized_light'));
        this.editor.setOptions({
            fontSize: this.fontSize ? this.fontSize : 18,
        });        
//
//        // Sets to use sublime key binding.
//        this.editor.setOption('keyMap', 'sublime');
//
        // Various improvements.
        this.editor.setOptions({
            behavioursEnabled: true,
            enableMultiselect: true,
            highlightActiveLine: true,
            printMargin: true,
            showLineNumbers: true,
            tabSize: 2,
            useSoftTabs: true,
            wrap: true,
            wrapBehavioursEnabled: true,
        }); 

        // Decides ruler.
        if (this.fileType === 'text' || this.fileType === 'markdown') {
            this.editor.setOptions({
                printMargin: false,
            });  
        } else if (this.ruler) {
            this.editor.setOptions({
                printMarginColumn: parseInt(this.ruler),
                printMargin: true,
            });  
        } else {
            this.editor.setOptions({
                printMarginColumn: 80,
                printMargin: true,
            }); 
        }
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
    ace.require("ace/ext/language_tools");
    var editor = ace.edit("editor");
    rfe = new RemoteFileEditor(editor);
    
    rfe.editorFontSize = gup('fontsize');
    rfe.filePath = gup('file');
    rfe.initialLineNumber = gup('linenumber');
    rfe.mode = gup('mode');
    rfe.ruler = gup('ruler');
    rfe.theme = gup('theme');
    
    rfe.setOptions();
    rfe.startMe();
});
