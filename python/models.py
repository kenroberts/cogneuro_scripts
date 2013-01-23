 # -*- coding: utf-8 -*-

"""redo as sqlalchemy declarative"""

import os
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from datetime import *


#dbdir=os.path.join(os.path.expanduser("~"),".pyqtodo")
#dbfile=os.path.join(dbdir,"tasks.sqlite")
dbdir = r'C:\Users\kcr2\Desktop\cogneuro_scripts\python'
dbfile = os.path.join(dbdir, r'xfer_files.sqlite')

Base = declarative_base()


class WatchDir(Base):
    """
    A watched directory
    """

    __tablename__ = 'watchDir'

    id = Column(Integer, primary_key=True)
    dirPath = Column(String(200))
    dateStarted = Column(DateTime)
    sendToComputer = Column(String(32))
    sendToDirectory = Column(String(200))
    isWatchingSubdirs = Column(Boolean)
    #tags  = ManyToMany("Tag")

    #def __init__(self, dirPath, dateStarted,
    #             sendToComputer, sendToDirectory, isWatchingSubdirs):
    #    self.dirPath = dirPath
    #    self.dateStarted = dateStarted
        

    def __repr__(self):
        return "WatchDir: " + self.dirPath


class TransferTask(Base):
    """
    A file transfer task
    first a file is detected, then added to a list of transfers
    """
    __tablename__ = 'transferTask_table'
    id = Column(Integer, primary_key=True)
    filePath = Column(String(200))
    fileName = Column(String(32))
    fileSize = Column(Integer)
    fileStatus = Column(Integer)
    dateAdded = Column(DateTime)

    fileStatusEnum = {1: 'Pending', 2: 'Transferred', }

    #def __init__(self, filePath, fileName, fileSize,
    #             fileStatus, dateAdded):
    #    self.filePath = filePath
    #    self.fileName = fileName
    #    self.fileSize = fileSize
    #    self.fileStatus = fileStatus
    #    self.dateAdded = dateAdded

    def getFileSize(self):
        if self.fileSize < 1000:
            return '%3d B' % self.fileSize
        elif self.fileSize < 1000000:
            return '%3d kB' % round(self.fileSize/1000)
        elif self.fileSize < 1000000000:
            return '%3d MB' % round(self.fileSize/1000000)
        else:
            return '%3d GB' % round(self.fileSize/1000000000)

    
    def getFileStatus(self):
        return TransferTask.fileStatusEnum[self.fileStatus]

    def getList(self):
        return [self.filePath, self.fileName, self.getFileSize(), self.getFileStatus()]

    def __repr__(self):
        return "<TransferTask(%s)> " % self.fileName


engine = None

def initDB():
    global engine
    if not os.path.isdir(dbdir):
        os.mkdir(dbdir)
    engine = create_engine(r'sqlite:///%s' % dbfile)
    Base.metadata.bind = engine
    Base.metadata.create_all()

def getSession():
    Session = sessionmaker(bind=engine)
    session = Session()
    return session

def main():

    # Initialize database
    initDB()
    
    Session = sessionmaker(bind=engine)
    session = Session()
    

    # Create one watchDir
    d1 = WatchDir(dirPath=r'C:\Users\kcr2\Desktop\cogneuro_scripts\python\test_watcher',
                  dateStarted=datetime.utcnow(),
                  sendToComputer=r'woldorffserv.ccn.duke.edu',
                  sendToDirectory=r'/',
                  isWatchingSubdirs=False)
    session.add(d1)
    session.commit()

    #Create a transferTask
    tt1 = TransferTask(filePath=r'C:\users\kcr2\cogneuro_scripts\python\test_watcher',
                    fileName='1800.cnt',
                    fileSize=12450,
                    fileStatus=1,
                    dateAdded=datetime.utcnow())
    tt2 = TransferTask(filePath=r'C:\users\kcr2\cogneuro_scripts\python\test_watcher',
                    fileName='1801.cnt',
                    fileSize=124708,
                    fileStatus=1,
                    dateAdded=datetime.utcnow())
    session.add(tt1)
    session.add(tt2)
                   
    session.commit()

    num_tasks = session.query(TransferTask).count()
    print('NumTasks = %d' % num_tasks)
    #num_dirs = WatchDir.query.all().count()
    
    # print('There are %d tasks and %d dirs being watched.' %
    #      (num_tasks, num_dirs ) )

    #for task in TransferTask.query.all():
    #    print(task)

if __name__ == "__main__":
    main()
