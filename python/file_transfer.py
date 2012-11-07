import ftplib
import logging

#logging.basicConfig(filename='example.log',level=logging.DEBUG)
#logging.debug('This message should go to the log file')
#logging.info('So should this')
#logging.warning('And this, too')
# http://docs.python.org/2/howto/logging.html

# given subject #, mkdir and chdir into it, if it doesn't exist already

# transfer a list of files

# return status

# simple test of the ftp connection
if __name__ == '__main__':

    logging.basicConfig(filename='example.log',level=logging.DEBUG)

    ftps = ftplib.FTP_TLS('woldorffserv.ccn.duke.edu')

    ftps.login('exp_archiver', 'woldorfflab')

    ftps.prot_p()

    ftps.dir()

    ftps.close()

    #ftps.storbinary()
