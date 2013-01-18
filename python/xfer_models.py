 # -*- coding: utf-8 -*-

"""A simple backend for a TODO app, using Elixir"""

import os
from elixir import *
from datetime import *

#dbdir=os.path.join(os.path.expanduser("~"),".pyqtodo")
#dbfile=os.path.join(dbdir,"tasks.sqlite")
dbdir = r'C:\Users\kcr2\Desktop\cogneuro_scripts\python'
dbfile = os.path.join(dbdir, r'xfer_files.sqlite')


class WatchDir(Entity):
    """
    A watched directory
    """
    using_options(tablename='watchDir_table')
    
    dirPath = Field(Unicode,required=True)
    dateStarted = Field(DateTime,default=None,required=False)
    sendToComputer = Field(Unicode,required=True)
    sendToDirectory = Field(Unicode,required=True)
    isWatchingSubdirs = Field(Boolean,default=False,required=True)
    #tags  = ManyToMany("Tag")

    def __repr__(self):
        return "WatchDir: " + self.dirPath


class TransferTask(Entity):
    """
    A file transfer task
    first a file is detected, then added to a list of transfers
    """
    using_options(tablename='transferTask_table')
    filePath = Field(Unicode,required=True)
    fileName = Field(Unicode,required=True)
    fileSize = Field(Integer,required=True)
    fileStatus = Field(Unicode,required=True)
    dateAdded = Field(DateTime,default=None,required=False)

    def __repr__(self):
        return "TransferTask: " + self.fileName


saveData=None

def initDB():
    if not os.path.isdir(dbdir):
        os.mkdir(dbdir)
    metadata.bind = r'sqlite:///%s' % dbfile
    print(metadata.bind)
    setup_all()
    if not os.path.exists(dbfile):
        create_all()

    # This is so Elixir 0.5.x and 0.6.x work
    # Yes, it's kinda ugly, but needed for Debian
    # and Ubuntu and other distros.

    global saveData
    import elixir
    if elixir.__version__ < "0.6":
        saveData=session.flush
    else:
        saveData=session.commit



def main():

    # Initialize database
    initDB()

    # Create one watchDir
    d1 = WatchDir(dirPath=r'C:\Users\kcr2\Desktop\cogneuro_scripts\python\test_watcher',
                  dateStarted=datetime.utcnow(),
                  sendToComputer=r'woldorffserv.ccn.duke.edu',
                  sendToDirectory=r'/',
                  isWatchingSubdirs=False)

    #Create a transferTask
    tt1 = TransferTask(filePath=r'C:\users\kcr2\cogneuro_scripts\python\test_watcher',
                    fileName='1800.cnt',
                    fileSize=12450,
                    fileStatus='Pending',
                    dateAdded=datetime.utcnow())
    tt2 = TransferTask(filePath=r'C:\users\kcr2\cogneuro_scripts\python\test_watcher',
                    fileName='1801.cnt',
                    fileSize=124708,
                    fileStatus='Pending',
                    dateAdded=datetime.utcnow())
    
                     
    saveData()

    num_tasks = TransferTask.query.all()
    print(class(num_tasks))
    #num_dirs = WatchDir.query.all().count()
    
    # print('There are %d tasks and %d dirs being watched.' %
    #      (num_tasks, num_dirs ) )

    #for task in TransferTask.query.all():
    #    print(task)

if __name__ == "__main__":
    main()
