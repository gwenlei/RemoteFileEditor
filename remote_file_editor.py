#! /usr/bin/env python
# -*- coding: utf-8 -*-   
import argparse
import io
import os
import threading  
import time
import re 
import fileinput 
import datetime
import pexpect
import json
import shutil
import multiprocessing
import threading

from flask import Flask, Response, request, jsonify, request, redirect, url_for, render_template
from werkzeug import secure_filename

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
ALLOWED_EXTENSIONS = set(['txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'])

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

def store(data):
    with open('links/jobs.json', 'w') as json_file:
        json_file.write(json.dumps(data))

def load():
    with open('links/jobs.json') as json_file:
        data = json.load(json_file)
        return data

def get_file_type(file_path):
    ext = os.path.splitext(file_path)[1][1:]
    return EXT_TYPE_MAPPING.get(ext, 'text')


@app.route('/list', methods=['GET'])
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
                '<a href="/edit?file=%s" target="_blank">edit</a>' %
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
            shutil.rmtree(file_path,True)
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


def copyFiles(sourceDir, targetDir):   
    print sourceDir
    for f in os.listdir(sourceDir):
        sourceF = os.path.join(sourceDir, f)
        targetF = os.path.join(targetDir, f)
        if os.path.isfile(sourceF): 
            #创建目录   
            if not os.path.exists(targetDir):
                os.makedirs(targetDir)
            #文件不存在，或者存在但是大小不同，覆盖   
            if not os.path.exists(targetF) or (os.path.exists(targetF) and (os.path.getsize(targetF) != os.path.getsize(sourceF))): 
                #2进制文件 
                open(targetF, "wb").write(open(sourceF, "rb").read()) 
                print u"%s %s 复制完毕" %(time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time())), targetF) 
            else: 
                print u"%s %s 已存在，不重复复制" %(time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time())), targetF) 
        if os.path.isdir(sourceF):   
            copyFiles(sourceF, targetF)  

def replaceInFile(filename, strFrom, strTo):  
    for line in fileinput.input(filename, inplace=True):  
        if re.search(strFrom, line):  
            line = line.replace(strFrom, strTo)  
        print line

@app.route('/newjob', methods=['GET'])
def new_job():
    global jobs
    builder = request.args['builder']
    os_type = request.args['os_type']
    job_time = time.strftime("%Y%m%d%H%M%S",time.localtime())
    targetDir = r"links/result/%s" % job_time
    if not check_file_path_validity(targetDir):
        return Response('Permission denied', 403)

    try:
        sourceDir = r"links/%s/%s" % (builder,os_type)
        print 'sourceDir: %s' % sourceDir
        if not check_file_path_validity(sourceDir):
            return Response('Permission denied', 403)
        copyFiles(sourceDir,targetDir) 
        jsonfile = "%s/json/%s.json" % (targetDir, os_type)
        print 'jsonfile: %s' % jsonfile
        replaceInFile(jsonfile,'TIMESTAMP',job_time)
        jobs[job_time]= {
            "builder": builder, 
            "os_type": os_type, 
            "jsonfile": jsonfile,
            "status": "job create",
            "cost_time": 0}
        return Response('New job %s created.' % targetDir, 200)
    except OSError as e:
        print '[Error] New job error: %s' % str(e)
        return Response(str(e), 500)

def manager():
    global jobs
    while True:
        store(jobs)
        time.sleep(10)
        for (k, v) in jobs.items():
            if jobs[k]['status'] == "waiting":
                print 'start job %s \n' %(jobs[k])
                t =threading.Thread(target=runpacker,args=(jobs[k]['jsonfile'],))
                t.start()
                t.join()
                break

def runpacker(file_path):
    global jobs
    print 'runpacker:[%s]\n' %(file_path)
    for (k, v) in jobs.items():
        if jobs[k]['jsonfile'] == file_path: break
    if jobs[k]['jsonfile'] != file_path:
        print 'job not record %s \n' %(file_path)
        exit(0)
    if jobs[k]['status']=="done":
        print 'job done %s \n' %(file_path)
        exit(0)            
    if not check_file_path_validity(file_path):
        jobs[k]['status']="error"
        exit(0)            
    jobs[k]['status']="building"
    start_time = datetime.datetime.now()
    stop_time = datetime.datetime.now()
    cmd = "/home/packerdir/packer build %s" % file_path
    p = pexpect.spawn(cmd)
    fout = file('%s.log' % file_path,'w')
    p.logfile = fout
    try:
        ret = p.expect([".*?Builds finished. The artifacts of successful builds are:*?"], timeout=None)
        if ret == 0:
            jobs[k]['status']="done"
            print 'packer build success %s \n' %(file_path)
        else:
            jobs[k]['status']="error"
            print 'packer build error %s \n' %(file_path)
    except pexpect.EOF:
        print 'packer build EOF %s \n' %(file_path)
        jobs[k]['status']="error"
    stop_time = datetime.datetime.now()
    cost_time = (stop_time - start_time).seconds
    jobs[k]['cost_time']=cost_time


@app.route('/packer', methods=['GET'])
def packer_build():
    global jobs
    file_path = request.args['file']
    if not check_file_path_validity(file_path):
        return Response('Permission denied', 403)

    try:
        for (k, v) in jobs.items():
            if jobs[k]['jsonfile'] == file_path: 
                jobs[k]['status']="waiting"
                print '[Info] job start %s' % file_path
                return Response('job start %s .' % file_path, 200)
        print 'job not record %s \n' %(file_path)
        jobs[k]['status']="error"
        return Response('job not record %s .' % file_path, 200)
    except OSError as e:
        print '[Error] packer build error: %s' % str(e)
        return Response(str(e), 500)

@app.route('/jobs', methods=['GET'])
def get_tasks():
    global jobs
    return jsonify({'jobs': jobs})

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS

@app.route('/upload', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        file = request.files['file']
        folder = request.form['folder']
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(folder, filename))
            return redirect(url_for('upload_file',
                                    filename=filename))
    return '''
    <!doctype html>
    <title>Upload new File</title>
    <h1>Upload new File</h1>
    <form action="" method=post enctype=multipart/form-data>
      <p><input type=file name=file>
      <p>folder: <input type="text" name="folder" /></p>
      <p><input type=submit value=Upload>
    </form>
    '''

@app.route('/')
def report():
    global jobs
    store(jobs)
    return render_template('report.html')

@app.route('/clean', methods=['GET'])
def clean():
    global jobs
    timestamp = request.args['file']
    del(jobs[timestamp])
    file_path = 'links/result/%s' % timestamp
    if not check_file_path_validity(file_path):
        return Response('Permission denied', 403)

    try:
        if os.path.isdir(file_path):
            shutil.rmtree(file_path,True)
            print '[Info] Rmdir directory: %s' % file_path
            return Response('Directory %s removed.' % file_path, 200)
        else:
            os.remove(file_path)
            print '[Info] Delete file: %s' % file_path
            return Response('File %s deleted' % file_path, 200)
    except OSError as e:
        print '[Error] Delete error: %s' % str(e)
        return Response(str(e), 500)


if __name__ == '__main__':
    global jobs
    jobs=load()
    d = threading.Thread(target=manager)
    d.daemon = True
    d.start()
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
