#! /usr/bin/env python
import argparse
import io
import os

from flask import Flask, Response, request

BASE_DIR = os.path.abspath(os.path.dirname(__file__))

app = Flask(__name__)

# Use this to do global configuration.
GLOBAL_CONFIG = {
    'allow_dot_files': False,
}

EXT_TYPE_MAPPING = {
    'css': 'text/css',
    'html': 'text/html',
    'js': 'text/javascript',
}


def get_file_type(file_path):
    ext = os.path.splitext(file_path)[1][1:]
    return EXT_TYPE_MAPPING.get(ext, 'text')


@app.route('/', methods=['GET'])
def homepage():
    return serve_file('./')


FILES_PAGE_CSS = """
<style>
.right-space {
    padding-right: 10px;
}
.li-file {
}
.li-dir {
    color: #FF33CC;
}
</style>
"""


class SimpleCache(object):
    def __init__(self, size):
        self._size = size
        self._cache = {}

    def put(self, key, value):
        self._cache[key] = value
        if len(self._cache) > self._size:
            self._cache = {}

    def get(self, key, default=None):
        return self._cache.get(key, default)

VALIDITY_CACHE = SimpleCache(50000)


def check_file_validity(file_path):
    cached_validity = VALIDITY_CACHE.get(file_path)
    if cached_validity != None:
        return cached_validity

    file_path = os.path.abspath(file_path)

    validity = True
    if not file_path.startswith(BASE_DIR):
        validity = False
    if not GLOBAL_CONFIG['allow_dot_files'] and os.path.basename(file_path).startswith('.'):
        validity = False

    if not validity:
        print '[Warning] Invalid path: ' + file_path

    VALIDITY_CACHE.put(file_path, validity)
    return validity

def check_file_path_validity(file_path):
    file_path = os.path.abspath(file_path)

    validity = True
    while check_file_validity(file_path):
        if file_path == BASE_DIR:
            return True
        else:
            file_path = os.path.dirname(file_path)
    return False


def generate_path_bar(dir_path):
    """Generates a path string with links to various directories."""
    dir_path = os.path.abspath(dir_path)
    cwd = os.path.abspath(os.getcwd())

    path_bar = ''
    while dir_path.startswith(cwd):
        base_dir, sub_dir = os.path.split(dir_path)
        path_bar = '<a href="/%s">%s</a>/%s' % (
            os.path.relpath(dir_path), sub_dir, path_bar)
        dir_path = base_dir

    path_bar = '%s/%s' % (dir_path, path_bar)
    return path_bar


def list_files(dir_path):
    """Generates a pretty list of files under a path."""
    files = sorted(os.listdir(dir_path.rstrip('/')), key=lambda x: x.lower())

    files_list = ''
    dirs_list = ''
    for a_file in files:
        full_path = os.path.join(dir_path, a_file)

        # Makes sure invalid files are not even listed.
        if not check_file_path_validity(full_path):
            continue

        # Generates report page.
        one_line = '<a href="%s" class="right-space">%s</a>' % (
            os.path.join('/', full_path), a_file)
        if os.path.isfile(full_path):
            one_line += (
                '<a href="/edit?file=%s" target="_blank">open in code editor</a>' %
                full_path)
            files_list += '<li class="li-file">%s</li>' % one_line
        else:
            one_line = '<em>%s</em>' % one_line
            dirs_list += '<li class="li-dir">%s</li>' % one_line

    show_files_page = '<h2>%s:</h2><ul>%s</ul><ul>%s</ul>' % (
        generate_path_bar(dir_path), dirs_list, files_list)
    return FILES_PAGE_CSS + show_files_page


@app.route('/<path:file_path>', methods=['GET'])
def serve_file(file_path):
    if not check_file_path_validity(file_path):
        return Response('Permission denied', 403)

    if os.path.isdir(file_path):
        print '[Info] GET path: %s' % file_path
        response = list_files(file_path)
        return Response(response, 200)

    file_type = get_file_type(file_path)
    if os.path.exists(file_path):
        print '[Info] GET file (%s): %s' % (file_type, file_path)
        return Response(file(file_path).read(), mimetype=file_type)
    else:
        print '[Info] GET new file: %s' % file_path
        return Response('', 200)


@app.route('/edit', methods=['GET'])
def edit_file():
    print '[Info] Edit: %s' % request.url
    return Response(file('editor/editor.html').read(), 200)


@app.route('/save', methods=['POST'])
def save_file():
    """Saves a file using a POST request.

    The request should be fileConfig={...}, where the config object contains
    filepath and fileContent fields.
    """
    file_path = request.form['filepath']
    file_content = request.form['filecontent']

    if not check_file_path_validity(file_path):
        return Response('Permission denied', 403)

    try:
        file_content = file_content.encode('utf-8')
        file(file_path, 'w+').write(file_content)
        print '[Info] File saved: %s' % file_path
    except UnicodeEncodeError:
        if os.path.splitext(file_path)[1] in ('.txt', '.html'):
            io.open(file_path, 'w+', encoding='utf-16').write(file_content)
            print '[Warning] Utf-16 file saved: ' + file_path
        else:
            return Response('Cannot save this type of file with utf-16!', 500)
    return Response('done', 200)


@app.route('/delete', methods=['GET'])
def delete_file():
    file_path = request.args['file']
    if not check_file_path_validity(file_path):
        return Response('Permission denied', 403)

    try:
        if os.path.isdir(file_path):
            os.rmdir(file_path)
            print '[Info] Rmdir directory: %s' % file_path
            return Response('Directory %s removed.' % file_path, 200)
        else:
            os.remove(file_path)
            print '[Info] Delete file: %s' % file_path
            return Response('File %s deleted' % file_path, 200)
    except OSError as e:
        print '[Error] Delete error: %s' % str(e)
        return Response(str(e), 500)


@app.route('/mkdir', methods=['GET'])
def make_directory():
    file_path = request.args['file']
    if not check_file_path_validity(file_path):
        return Response('Permission denied', 403)

    try:
        os.makedirs(file_path)
        print '[Info] Mkdir directory: %s' % file_path
        return Response('Directory %s created.' % file_path, 200)
    except OSError as e:
        print '[Error] Delete error: %s' % str(e)
        return Response(str(e), 500)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Starts a file editor server.')
    parser.add_argument(
        '-p', '--port', type=int, default=9000, help='the port to start the server on')
    parser.add_argument(
        '-adf', '--allow-dot-files', action='store_true', dest='allow_dot_files', default=False,
        help='allow to access dot files')
    parser.add_argument(
        '-d', '--debug', action='store_true', dest='debug', default=False,
        help='whether to enable debug mode')
    args = parser.parse_args()

    # Tweak configs.
    if args.allow_dot_files:
        GLOBAL_CONFIG['allow_dot_files'] = True

    app.run(host='0.0.0.0', port=args.port, debug=args.debug, threaded=True)
