from flask import Flask, render_template, send_from_directory, request
from python_terraform import *
import os
import yaml
import hcl
import uuid
import json

app = Flask(__name__)
tf = Terraform()

MODULES_PATH = os.path.join('..', 'modules')

# Returns list of module objects with metadata
def get_modules():
	module_names = os.listdir(MODULES_PATH)
	return [get_module_details(module_name) for module_name in module_names]

# Given module, get metadata
def get_module_details(module_name):
	with open(os.path.join(MODULES_PATH, module_name, 'databricks.yaml'), 'r') as detail_file,\
		 open(os.path.join(MODULES_PATH, module_name, 'variables.tf')) as variable_file:

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

def get_target_dir(module_name):
	return os.path.join(MODULES_PATH, module_name)

def get_plan_path(plan_id):
	return os.path.join('..', 'user', 'plans', plan_id)

def get_state_path(state_name):
	return os.path.join('..', 'user', 'states', state_name)

def exec_plan(module_name, variables):
	plan_id = str(uuid.uuid4())[:7]
	target_dir = get_target_dir(module_name)
	state_path = get_state_path(module_name)
	out_path = get_plan_path(plan_id)

	tf.init(os.path.join(MODULES_PATH, module_name))
	plan = tf.plan(target_dir, state=state_path, out=out_path, variables=variables.to_dict())

	return plan, plan_id

# def init_all_modules():
# 	module_names = os.listdir(MODULES_PATH)

# 	for module_name in module_names:
# 		tf.init(os.path.join(MODULES_PATH, module_name))

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
	return render_template('module.html', module=module)


# API:

@app.route("/plan/<module_name>", methods=["POST"])
def plan(module_name):
	variables = request.form
	plan_result, plan_id = exec_plan(module_name, variables)
	module = get_module_details(module_name)

	return render_template('plan.html', module=module, variables=variables, plan_result=plan_result, plan_id=plan_id)

@app.route("/apply/<plan_id>", methods=["POST"])
def apply(plan_id):
	plan_path = get_plan_path(plan_id)
	return json.dumps(tf.apply(plan_path, refresh=True, auto_approve=True))
