from setuptools import setup, find_packages

setup(name='databricks-cloud-automation',
	version='1.0.0',
	description='Databricks Cloud Automation',
	url='databricks.com',
	author='Databricks',
	author_email='sales@databricks.com',
	license='TBD',
	zip_safe=False,
	packages=find_packages(),
	install_requires=[
		'Flask',
		'pyyaml',
		'python-terraform',
		'pyhcl',
		'gunicorn'
	],
	entry_points='''
        [console_scripts]
        databricks-cloud-manager=dca_ui.cli:cli
    '''
)