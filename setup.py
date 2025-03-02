from importlib.metadata import entry_points
from setuptools import setup,find_packages
setup(
    name="hello_python",
    version="0.1.0",
    author="yuepo",
    description="A simple hello python package",
    packages=find_packages(where="src"),
    package_dir={"":"src"},
    entry_points={
        "console_scripts":[
            "hellopython=testpython:say_hello"
        ]
    },
)
