#!/usr/bin/env python
# -*- coding: utf-8 -*-
import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()
    setuptools.setup(
        name='brewmon',
        version='0.1',
        scripts=['scripts/bm-import', 'scripts/bm-install.sh', 'scripts/bm-uninstall.sh'],
        author="Benoit Delbosc",
        description="Grafana dashboard to monitor beer fermentation",
        long_description=long_description,
        long_description_content_type="text/markdown",
        url="https://github.com/bdelbosc/brewmon",
        packages=setuptools.find_packages(),
        install_requires=['influxdb>=5.2.0'],
        data_files=[("/etc/influxdb", ["etc/influxdb/influxdb.conf"]),
                    ("/etc/grafana/provisioning/dashboards",
                     ["etc/grafana/provisioning/dashboards/dashboard.yml",
                      "etc/grafana/provisioning/dashboards/brewpi.json"]),
                    ("/etc/grafana/provisioning/datasources",
                     ["etc/grafana/provisioning/datasources/default.yml"])],
        include_package_data=True,
        classifiers=[
            'Programming Language :: Python :: 2.7',
            'Development Status :: 3 - Alpha',
            'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
            'Operating System :: OS Independent',
            'Intended Audience :: Manufacturing',
        ],

    )
