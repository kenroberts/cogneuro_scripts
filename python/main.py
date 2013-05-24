# -*- coding: utf-8 -*-

"""The user interface for our app"""

import os,sys
import resources_rc
import logging
import models

# Import Qt modules
from PyQt4 import QtCore,QtGui

# Import the compiled UI module
from windowUi import Ui_MainWindow

# Create a class for our main window
class Main(QtGui.QMainWindow):
    def __init__(self):
        QtGui.QMainWindow.__init__(self)
        
        # This is always the same
        self.ui=Ui_MainWindow()
        self.ui.setupUi(self)
 
        self.setup_systray()

    def setup_systray(self):
        # context menu for systray
        app_icon = QtGui.QIcon(':/resource/icons/important.png')
        systray_icon = QtGui.QSystemTrayIcon(app_icon, self)
        systray_menu = QtGui.QMenu(self)

        # systray_menu.setTitle("Foo")
        showAction = systray_menu.addAction('Show Application') # QtGui.QAction('Show Application')
        showAction.triggered.connect(self.showApplication)
        systray_icon.setContextMenu(systray_menu)
        systray_icon.show()

    def refresh_treeview(self):
        # query all pending items
        session = models.getSession()
        for task in session.query(models.TransferTask).filter(models.TransferTask.fileStatus==1):
            item=QtGui.QTreeWidgetItem(task.getList())
            self.ui.treeWidget.addTopLevelItem(item)

    def showApplication(self):
        
        self.refresh_treeview()

        # show
        self.show()


# properties that are stored
class Properties:

    def __init__(self):
        self.prop_dir = None
        

# directory watcher
# classic model of mvc
class DirWatcher:
    def __init__(self):
        # setup simple logger
        logging.basicConfig(filename='example.log',level=logging.DEBUG)
        self.fs_watcher = None
        # who to notify

    def log_dirchange(self, msg):
        logging.info('log dirchange on ' + msg)

    def add_to_queue(self, filepath):
        xfer_models.TransferTask(filePath=r'C:\users\kcr2\cogneuro_scripts\python\test_watcher',
                    fileName='1800.cnt',
                    fileSize=12450,
                    fileStatus=1,
                    dateAdded=datetime.utcnow())
        xfer_models.saveData()
        pass

    def add_directory(self, dirname):
        if self.fs_watcher == None:
            self.fs_watcher = QtCore.QFileSystemWatcher()
            self.fs_watcher.directoryChanged.connect(self.log_dirchange)
        logging.info('watching ' + dirname)
        self.fs_watcher.addPath(dirname)
        

def main():
    # Again, this is boilerplate, it's going to be the same on 
    # almost every app you write
    app = QtGui.QApplication(sys.argv)
    app.setApplicationName('AutoXfer App')

    models.initDB()

    window=Main()
    # window.show()

    # try out watching a directory
    dir_watcher = DirWatcher()
    
    # the_dir = r'C:\Users\kcr2\Desktop\cogneuro_scripts\python\test_watcher'
    the_dir = r'test_watcher'
    dir_watcher.add_directory(the_dir)
    
    # It's exec_ because exec is a reserved word in Python
    sys.exit(app.exec_())
    

if __name__ == "__main__":
    main()
    
