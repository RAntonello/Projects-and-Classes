# http://www.darkcoding.net/software/pretty-command-line-console-output-on-unix-in-python-and-go-lang/	
import sys
import fcntl
import termios
import struct

COLS = struct.unpack('hh',	fcntl.ioctl(sys.stdout, termios.TIOCGWINSZ, '1234'))[1]

def bold(msg):
	return u'\033[1m%s\033[0m' % msg

def progress(current, total):
	prefix = '%d / %d' % (current, total)
	bar_start = ' ['
	bar_end = '] '

	bar_size = COLS - len(prefix + bar_start + bar_end)
	amount = int(current / (total / float(bar_size)))
	remain = bar_size - amount

	bar = 'X' * amount + ' ' * remain
	return bold(prefix) + bar_start + bar + bar_end

def print_progress(current, total):
	sys.stdout.write(progress(current, total) + '\r')
	sys.stdout.flush()