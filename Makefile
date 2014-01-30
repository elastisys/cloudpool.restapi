DOCS_DIR = docs
# virtual environment to create
VIRTUALENV = virtualenv.restapi

.PHONY: docs

virtualenv:
	virtualenv $(VIRTUALENV)

init: 
	pip install -r requirements.txt

clean:
	$(MAKE) -C $(DOCS_DIR) clean

docs:
	# Render HTML documentation from rST sources
	$(MAKE) -C $(DOCS_DIR) html SPHINXBUILD="python $$(which sphinx-build)"


showdocs: docs
	xdg-open $(DOCS_DIR)/_build/html/index.html
