# from os import getcwd
import csv
import sqlite3

import http.server
import urllib.parse

import os
from datetime import datetime

# goal: a program that will index ALL of the .cnt files, and all of the .log
# files on a filesystem.

# basic class to walk a directory and yield file information
# extensions are the filetypes that FileWalker will return
# also, prohibited directories can be added.
# notes: does not follow symbolic links.
# depends: os, datetime
class FileWalker:
    '''A persistent store for file metadata'''

    def __init__(self, base_path):
        """Takes a base path to walk for indexing."""
        self.base_path = base_path
        self.extensions = set()
        self.novisit = set()
        self.dircount = 0
        self.filecount = 0
        
    def add_extension(self, ext):
        """The FileWalker will collect files with certain
        extensions.  These extensions can be added by this function.
        Extensions must be three letters plus
        filesep (ie, ".txt" or ".doc") """
        assert(len(ext) == 4)
        self.extensions.add(ext)

    def add_novisit(self, some_dir):
        self.novisit.add(some_dir)
    
    def generator(self):
        for curr_dir, subdirs, files in os.walk(self.base_path):
            for d in subdirs:
                self.filecount++
                if d in self.novisit:
                    subdirs.remove(d)
            for f in files:
                self.dircount++
                if f[-4:] in self.extensions: 
                    yield '{0} in {1}'.format(f, curr_dir)

    def list_generator(self):
        for curr_dir, subdirs, files in os.walk(self.base_path):
            for d in subdirs:
                if d in self.novisit:
                    subdirs.remove(d)
            for f in files:
                if f[-4:] in self.extensions:
                    fs = os.stat(os.path.join(curr_dir, f))
                    # fname, subdir, size, atime, ctime
                    yield [f, curr_dir, int(fs.st_size),
                            str(datetime.fromtimestamp(fs.st_atime)),
                            str(datetime.fromtimestamp(fs.st_ctime)) ]  


# basic class to serve up web pages from a database
# depends: httpserver
class DBServer(http.server.HTTPServer):
        
    def set_dbname(self, dbname):
        self.db_name = dbname
        
    def get_dbname(self):
        return self.db_name


# basic class to serve up web pages from a database
# depends: httpserver, urllib
class DBReqHandler(http.server.BaseHTTPRequestHandler):

    def do_GET(self):
        parsed_path = urllib.parse.urlparse(self.path)
        
        message = '''
            <html><head><title>Simple App</title></head><body>
            <h1>Output</h1>
            '''
        
        if True:
            # print simple table of results
            fdb = FileDB(self.server.db_name)
            message = message + '<table>'
            for row in fdb.fetch_rows(1, 10):
                message = message + '<tr><td>'
                message = message + '</td><td>'.join(row)
                message = message + '</td></tr>'
            message = message + '</table>'
            
        
        message = message + '</body></html>'

        self.send_response(200)
        self.end_headers()
        self.wfile.write(bytes(message, 'UTF-8'))

    def debug_str():
        message = '\n'.join([
                'CLIENT VALUES:',
                'client_address = %s (%s)' % (self.client_address,
                                            self.address_string()),
                'command = %s' % self.command,
                'path = %s' % self.path,
                'real path = %s' % parsed_path.path,
                'query = %s' % parsed_path.query,
                'request_version = %s' % self.request_version,
                '',
                'SERVER VALUES:',
                'server_version = %s' % self.server_version,
                'sys_version = %s' % self.sys_version,
                'protocol_version = %s' % self.protocol_version,
                'server database = %s' % self.server.get_dbname(),
                ])
        message = message + '\n' + 'SERVER METHODS' + '\n'
        message = message + '\n'.join(dir(self))
        return message

# MODULE: FILEDB
# creates an sqlite db that holds files and their attributes
# by either walking a file hierarchy, or by reading from a csv.
# depends: sqlite3, csv
class FileDB:

    def __init__(self, dbfile):
        """Pass in existing or new filename."""
        self.dbfile = dbfile
        self.conn = sqlite3.connect(self.dbfile)

        # create tables if necc.
        c = self.conn.cursor()
        c.execute("""select name from sqlite_master
                  where name='filestats' and
                  type='table'
                  """)
        if not c.fetchone():
            print('Generating table.')
            c.execute("""create table filestats
                    (tag text, name text,
                    path text, size text,
                    last_change text, last_access text)
            """)
            self.conn.commit()
        c.close()

    def __del__(self):
        self.conn.close()

    def fetch_rows(self, start, number):
        c = self.conn.cursor()
        c.execute('select * from filestats limit %s' % number)
        for row in c:
            yield row
    
    def import_csv(self, csvFilename):

        """ Note: Windows: modified, created
                CSV: last_access, last_change
                Linux: accessed, modified (only file), changed (file or metadata)
        """

        tag = csvFilename
        ts = datetime.now()
        rowReader = csv.reader(open(csvFilename, 'rb'))
        c = self.conn.cursor()

        # fill db with data (skip first 6 lines of file)
        for i, row in enumerate(rowReader):
            if i > 6:
                row = row[0:5]
                row.insert(0, tag)
                c.execute("insert into filestats values (?,?, ?,?, ?,?)",
                  tuple(row))
            
        self.conn.commit()

        # do a simple select
        c.execute('select count(*) from filestats')

        print('{0} rows were imported in {1}.'.format(
            c.fetchone(), str(datetime.now()-ts)))

        c.close()

    def import_filewalk(self, filedir, extension):

        """Note: Windows: modified, created
                CSV: last_access, last_change
                Linux: accessed, modified (only file), changed (file or metadata)
        """

        tag = 'hardcoded_tag'
        ts = datetime.now()
        
        fw = FileWalker(filedir)
        fw.add_extension(extension)

        # init database   
        c = self.conn.cursor()

        # fill db with data 
        for entry in fw.list_generator():
            entry.insert(0, tag)
            c.execute("insert into filestats values (?,?, ?,?, ?,?)",
                  tuple(entry))
            
        self.conn.commit()

        # do a simple select
        c.execute('select count(*) from filestats')

        print('{0} rows were imported in {1}.'.format(
            c.fetchone(), str(datetime.now()-ts)))

        c.close()

# parse important properties from a presentation logfile
#
test = '''def class PresLogfileReader:

    def __init__(*arguments)
        fh = fopen(arguments[0])
        close(fh)'''


# switch between server, filewalker and db, logfile
testmode = 'server'
    
if __name__ == '__main__' and testmode == 'server':
    CLIENT_PORT = ('', 8000)
    '''httpd = DBServer(CLIENT_PORT,
                    DBReqHandler)'''
    #httpd = BaseHTTPServer.HTTPServer(CLIENT_PORT, DBReqHandler)
    httpd = DBServer(CLIENT_PORT, DBReqHandler)
    httpd.set_dbname('test.sq3')
    print('DB name:' + httpd.get_dbname())
    httpd.serve_forever()

if __name__ == '__main__' and testmode == 'db':
    """ This program will read csv files into an
    sqlite database
    """
    fdb = FileDB('test.sq3') # works
    #fdb.import_csv('allagash_exp_files.csv' # works

    fdb.import_filewalk(r'c:\Documents and Settings\kroberts\Desktop\data_archive\junk_2010',
                        '.log')

    # this works
    for r in fdb.fetch_rows(1, 24):
        print(r)

    # delete database
    fdb = None

if __name__ == "__main__" and testmode == 'filewalker':
    base_path = r'c:\Documents and Settings\kroberts\Desktop\data_archive\junk_2010'
    fw = FileWalker(base_path)
    fw.add_extension('.log')
    for s in fw.list_generator():
        print(s)

if __name == "__main__" and testmode == 'logfile':
    pres_logfile = PresLogfileReader('test.log')
    
