import os

if __name__ == "__main__":
    # build resource file
    os.system('pyrcc4 -py3 resources.qrc -o resources_rc.py')
    
    # build main gui
    os.system('pyuic4 window.ui -o windowUi.py')

    # build to an .exe
    os.system(r'c:\Python32\python.exe setup.py build')
    os.system('pause');
