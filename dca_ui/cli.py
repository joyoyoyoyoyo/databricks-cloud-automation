import subprocess

def cli():
	subprocess.call(['gunicorn', '-b', '127.0.0.1:5000', '-w', '1', 'dca_ui.__init__:app'])