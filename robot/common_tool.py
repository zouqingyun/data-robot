# -*- coding:utf-8 -*-

from hadoop_robot import execute_remote_cmd
from fabric.api import run, env, cd, execute, settings, local, hide
from fabric.operations import put, get


def set_hosts(host_file):
    env.hosts = open(host_file, "r").readlines()


def install_pip():
    if run("pip --help").return_code != 0:
        execute_remote_cmd("sudo yum install python-pip")
        execute_remote_cmd("sudo pip install -U pip ")


def install_pip_package(name=""):
    with settings(warn_only=True):
        install_pip()

        if run("pip list | grep {0}".format(name)).return_code != 0:
            execute_remote_cmd("sudo pip install {0}".format(name))