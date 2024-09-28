from setuptools import setup, find_packages

# Read the contents of your README file
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
        "pillow",
        # Add other dependencies here if needed
    ],
    include_package_data=True,  # Include data files as specified in MANIFEST.in
    package_data={
        # Define the directories and file types to be included in the package
        'automata': [
            'data/*',              # Include all files in 'data' directory
            'NodeRedLogic/*.json', # Include all JSON files in 'NodeRedLogic' directory
        ],
    },
    entry_points={
        'console_scripts': [
            # If you want to define custom commands that can be run from the console,
            # specify them here. Uncomment and modify if applicable.
            # 'automata-start=automata.some_module:start_function',
        ],
    },
)
