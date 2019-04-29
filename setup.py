from setuptools import setup, find_packages
from setuptools.command.install import install
import subprocess
import os

class PostInstall(install):
	def run(self):
		try:
			install.run(self)

			print("Post-install: Downloading and installing terraform...")
			pwd = os.path.dirname(os.path.abspath(__file__))
			post_install_path = os.path.join(pwd, 'post-install.sh')
			print(post_install_path)
			subprocess.call('sh ' + post_install_path, shell=True)
		except:
			print("Terraform install failed. You can finish installation manually by downloading the appropriate package here: https://www.terraform.io/downloads.html")
			raise
		print("Install complete. Run `databricks-cloud-manager` to begin.")


setup(name='databricks-cloud-automation',
	version='0.1.8',
	description='Databricks Cloud Automation',
	long_description='Databricks Cloud Automation uses Terraform to provision cloud infrastructure. You may use a prepackaged GUI or terraform directly to deploy these modules',
	url='http://www.databricks.com',
	author='Databricks',
	author_email='sales@databricks.com',
	license='Apache License 2.0',
	zip_safe=False,
	packages=find_packages(),
	cmdclass={
		'install': PostInstall
	},
	install_requires=[
		'Flask',
		'PyYAML',
		'python-terraform',
		'pyhcl',
		'gunicorn'
	],
	entry_points='''
        [console_scripts]
        databricks-cloud-manager=dca_ui.cli:cli
    '''
)
