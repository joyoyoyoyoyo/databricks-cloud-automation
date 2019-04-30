from flask import Flask, render_template, send_from_directory, request
from python_terraform import *
import os
import yaml
import hcl
import uuid
import json

tf = Terraform()
app = Flask(__name__)

ROOT_PATH = os.path.join(os.path.dirname(__file__), '..')
DEV_MODE = False

# Returns list of module objects with metadata
def get_modules():
	all_files = os.listdir(os.path.join(ROOT_PATH, 'modules'))
	module_names = [file for file in all_files if not file.startswith('.')]
	return [get_module_details(module_name) for module_name in module_names]

# Given module, get metadata
def get_module_details(module_name):
	with open(os.path.join(ROOT_PATH, 'modules', module_name, 'databricks.yaml'), 'r') as detail_file,\
		 open(os.path.join(ROOT_PATH, 'modules', module_name, 'variables.tf')) as variable_file:

		module_details = yaml.safe_load(detail_file)
		variables = hcl.load(variable_file)['variable']

		return {
			'name': module_name,
			'overview': module_details['overview'],
			'description': module_details['description'],
			'use_cases': module_details['use_cases'],
			'scope': module_details['scope'],
			'variables': variables
		}

def prune_var_secrets(variables):
	if DEV_MODE:
		return variables

	pruned_variables = dict()

	for k, v in variables.items():
		if not 'secret' in k:
			pruned_variables[k] = v

	return pruned_variables

def get_target_dir(module_name):
	return os.path.join(ROOT_PATH, 'modules', module_name)

def get_plan_path(plan_id):
	return os.path.join(ROOT_PATH, 'user', 'plans', plan_id)

def save_vars(variables, module_name):
	variables_no_secrets = prune_var_secrets(variables)

	with open(os.path.join(ROOT_PATH, 'user', 'vars', module_name + '.json'), 'w') as var_file:
		json.dump(variables_no_secrets, var_file)

def get_vars(module_name):
	try:
		with open(os.path.join(ROOT_PATH, 'user', 'vars', module_name + '.json'), 'r') as var_file:
			return json.loads(var_file.read())
	except:
		return None

def exec_plan(module_name, variables):
	plan_id = str(uuid.uuid4())[:7]
	target_dir = get_target_dir(module_name)
	state_path = os.path.join(ROOT_PATH, 'user', 'states', module_name + '.tfstate')
	out_path = get_plan_path(plan_id)
	init_res = tf.init(os.path.join(ROOT_PATH, 'modules', module_name), input=False, upgrade=True, get=True)
	version = tf.cmd('version')
	print('Terraform Version: ' + version[1])
	print('Using state located at' + state_path)
	plan = tf.plan(target_dir, refresh=True, state=state_path, out=out_path, variables=variables.to_dict())
	return plan, plan_id

# Serve public directory:

@app.route("/public/<path:path>")
def serve_public(path):
	return send_from_directory('public', path)

# Serve pages:

@app.route("/")
def index():
	modules = get_modules()	
	return render_template('index.html', modules=modules)

@app.route("/modules/<module_name>")
def module_page(module_name):
	module = get_module_details(module_name)
	existing_vars = get_vars(module_name)
	return render_template('module.html', module=module, variables=existing_vars)

# API:

@app.route("/plan/<module_name>", methods=["POST"])
def plan(module_name):
	variables = request.form
	plan_result, plan_id = exec_plan(module_name, variables)
	module = get_module_details(module_name)
	save_vars(variables, module_name)
	return render_template('plan.html', module=module, variables=variables, plan_result=plan_result, plan_id=plan_id)

@app.route("/apply/<plan_id>/<module_name>", methods=["POST"])
def apply(plan_id, module_name):
	plan_path = get_plan_path(plan_id)
	state_path = os.path.join(ROOT_PATH, 'user', 'states', module_name + '.tfstate')
	print("Saving state to: " + state_path)
	apply_res = tf.apply(plan_path, refresh=True, auto_approve=True, state_out=state_path)
	print(apply_res)
	return json.dumps(apply_res)
