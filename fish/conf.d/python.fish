# Python PIP and VENV
if type -q python
    set -gx PYTHONPATH (python -c "import site, os; print(os.path.join(site.USER_BASE, 'lib', 'python', 'site-packages'))"):$PYTHONPATH
end
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
# disabling for rtx/asdf
set -gx PIP_REQUIRE_VIRTUALENV 0
