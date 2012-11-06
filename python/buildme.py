import os

if __name__ == "__main__":
    # build resource file
    os.system('pyrcc4 -py3 resources.qrc -o resources_rc.py')
    # build gui
    os.system('pyuic4 window.ui -o windowUi.py')
