from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="automata-building-management",
    version="1.0.0",
    author="A. Jewell Sr",
    author_email="your.email@example.com",
    description="Automata Building Management & HVAC Controller - Advanced IoT-driven solution for commercial and industrial applications",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/AutomataControls/AutomataBuildingManagment-HvacController",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: End Users/Desktop",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
    ],
    python_requires=">=3.7",
    install_requires=[
        "tkinter",
        "pillow",
        # Add other dependencies here
    ],
    include_package_data=True,
    scripts=[
        'automata/scripts/AutomataControllerInstall.sh',
        'automata/scripts/Uninstall.sh',
        'automata/scripts/setup_mosquitto.sh',
        'automata/scripts/update_sequent_boards.sh',
        'automata/scripts/set_background.sh',
        'automata/scripts/increase_swap_size.sh',
        'automata/scripts/install_node_red.sh',
    ],
    package_data={
        'automata': [
            'data/*',
            'flows/*',
        ],
    },
    entry_points={
        'console_scripts': [
            'automata-install=automata.scripts.AutomataControllerInstall:main',
            'automata-start=automata.scripts.start:main',
        ],
    },
)
