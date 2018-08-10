# Convert state to configuration

import sys, os, json

STATE_FILENAME = 'terraform.tfstate'

def getResourceFromState(tfState, tfResourceName):
	print('Finding resource in current state')

	allModules = tfState['modules']
	targetModules = [module for module in allModules if tfResourceName in module['resources']]

	if len(targetModules) > 1:
		raise Exception('Resource found in multiple TF modules. Multiple TF modules not supported')
	if len(targetModules) < 1:
		raise Exception('Resource not found in any module')

	resourceState = tfState['modules'][0]['resources'][tfResourceName]
	resourceId, resourceAttrs = resourceState['primary']['id'], resourceState['primary']['attributes']
	
	print('Found resource "' + resourceId + '" with ' + str(len(resourceAttrs)) + ' attributes')
	
	return resourceId, resourceAttrs

def state2var(tfState, tfResourceName):
	resourceId, resourceAttrs = getResourceFromState(tfState, tfResourceName)
	importedVars = generateVars(resourceAttrs)
	





def getTfState():
	print('Reading state from file')

	tfStatePath = os.path.join(os.getcwd(), STATE_FILENAME)

	with open(tfStatePath) as file:
		tfState = json.load(file)

	print('Successfully read state file')
	
	return tfState


def main():
	tfState = getTfState()
	tfResourceName = sys.argv[1]
	return state2var(tfState, tfResourceName)

if __name__ == '__main__':
    main()
