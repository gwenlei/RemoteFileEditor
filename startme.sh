#! /usr/bin/env bash
fuser -n tcp -k 8999
./remote_file_editor.py --port=8999
