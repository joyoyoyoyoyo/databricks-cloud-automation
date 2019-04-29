import subprocess
import webbrowser

HOST = '127.0.0.1:5000'

def cli():
	subprocess.call(['gunicorn', '-b', HOST, '-w', '1', '-t', '0', 'dca_ui.__init__:app'])