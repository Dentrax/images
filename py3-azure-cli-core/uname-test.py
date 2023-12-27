# Just import the main module
import azure.cli.core
# Then import the subdir from there
from azure.cli import core

print(core.os.uname().sysname)
