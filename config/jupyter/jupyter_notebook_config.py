import json
import os
import sys

home = os.environ['HOME']
sys.path.append('{0}/.jupyter/extensions/'.format(home))

c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
c.NotebookApp.allow_credentials = True
c.NotebookApp.nbserver_extensions = {'jupyter_nbgallery.status':True, 'jupyter_nbgallery.post':True}
c.NotebookApp.reraise_server_extension_failures = True
c.NotebookApp.extra_static_paths = ['{0}/.jupyter/static'.format(home)]
c.NotebookApp.extra_nbextensions_path = ['{0}/.jupyter/extensions/'.format(home)]
c.NotebookApp.tornado_settings = {'static_url_prefix': '/Jupyter/static/'}
c.NotebookApp.allow_origin = 'https://nb.gallery'

# needed to receive notebooks from the gallery
c.NotebookApp.disable_check_xsrf = True

# Update config from environment
config_prefix = 'NBGALLERY_CONFIG_'
for var in [x for x in os.environ if x.startswith(config_prefix)]:
  c.NotebookApp[var[len(config_prefix):].lower()] = os.environ[var]

def load_config():
  return json.loads(open('{0}/.jupyter/nbconfig/common.json'.format(home)).read())

def save_config(config):
  with open('{0}/.jupyter/nbconfig/common.json'.format(home), 'w') as output:
    output.write(json.dumps(config, indent=2))

# Override gallery location
nbgallery_url = os.getenv('NBGALLERY_URL')
if nbgallery_url:
  print('Setting nbgallery url to %s' % nbgallery_url)
  c.NotebookApp.allow_origin = nbgallery_url
  config = load_config()
  config['nbgallery']['url'] = nbgallery_url
  save_config(config)

# Override client name
client_name = os.getenv('NBGALLERY_CLIENT_NAME')
if client_name:
  config = load_config()
  config['nbgallery']['client']['name'] = client_name
  save_config(config)
