# -*- coding: utf-8 -*-

"""The user interface for our app"""

import os,sys
import resources_rc
import logging

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

    def showApplication(self):
        self.show()
        

# directory watcher
class DirWatcher:
    def __init__(self):
        # setup simple logger
        logging.basicConfig(filename='example.log',level=logging.DEBUG)

    def print_signal(self, msg):
        logging.info(msg)

def main():
    # Again, this is boilerplate, it's going to be the same on 
    # almost every app you write
    app = QtGui.QApplication(sys.argv)
    app.setApplicationName('Xfer Data Demon')

    window=Main()
    # window.show()

    # context menu for systray
    app_icon = QtGui.QIcon(':/resource/icons/important.png')
    systray_icon = QtGui.QSystemTrayIcon(app_icon, window)
    systray_menu = QtGui.QMenu(window)
    # systray_menu.setTitle("Foo")
    showAction = systray_menu.addAction('Show Application') # QtGui.QAction('Show Application')
    showAction.triggered.connect(window.showApplication)
    systray_icon.setContextMenu(systray_menu)
    systray_icon.show()
    
    # systray icon, TODO add context menu
    # 
    # 
    # 
    
    
    

    

    # try out watching a directory
    dir_watcher = DirWatcher()
    dir_watcher.print_signal('System started.')
    fs_watcher = QtCore.QFileSystemWatcher()
    the_dir = r'C:\Users\kcr2\Desktop\cogneuro_scripts\python\test_watcher'
    fs_watcher.addPath(the_dir)
    fs_watcher.directoryChanged.connect(dir_watcher.print_signal)
    
    # It's exec_ because exec is a reserved word in Python
    sys.exit(app.exec_())
    

if __name__ == "__main__":
    main()
    
