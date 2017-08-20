# Remote File Editor
Remote file editor allows editing ASCII text files remotely on a host using a web interface with syntax highlighting.

## How to use it?
First install all the bower components by running:
> $ bower install

If you do not want to use bower, you can also unzip bower_components.zip to
provide all the components files.

Then just run the server on your host using:
> $ ./startme.sh

Running it requires the [Flask](http://flask.pocoo.org/) module.

Now you can browse to host:8999 (you can config this using --port) to see files under the running directory. You can click on the "open in code editor" link to edit a file. The changes you make will automatically (and *ALWAYS*) be saved on the host after a short delay for your every change.

Put the files you want to allow remote modification under the project directory, or put symbolic links for them. It is recommended that you create links under the *links* directory.

The following interfaces are supported:

* /_path_: This displays the content of a file or a directory with the given (relative) path.

* /edit?file=*path*: This opens an editor for the file with syntax highlighting.
  * You can use the "fontsize" parameter to set the editor font size. For example "&fontsize=16" sets editor font size to 16px.
  * You can use the "mode" parameter to set the syntax highlight mode. For example "&mode=javascript" forces the editor to treat the file as a javascript file. By default the editor guesses the mode from the file extension.

* /delete?file=*path*: This removes a file or an empty directory.

* /mkdir?file=*path*: This creates a directory (equivalent to "mkdir -p").

## More highlights
* A check in file path is implemented: only files whose path are under the project directory (link not expanded) are accessible.
* Supports editing Markdown files, in which case a live rendering is shown to the right.

## Currently known issues
* Only ASCII text files are supported; opening images etc. will result in errors.
* Editing the same file from multiple clients is NOT supported --- whoever saves later wins.

## Question/Suggestion?
Email chih.chiu.19@gmail.com
