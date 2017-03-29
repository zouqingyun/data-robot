# -*- coding:utf-8 -*-
from xml.etree import ElementTree as ET
from lxml import etree
from fabric.api import run, env, cd, execute, settings, local, hide
from fabric.operations import put, get
from fabric.utils import apply_lcwd
from glob import glob
import copy
import os.path
import datetime

env.roledefs = {
    "test-datanodes": ["vm10", "vm11", "vm12"]
}


def __to_bool(value):
    if str(value).lower() in ("yes", "y", "true",  "t", "1"): return True
    if str(value).lower() in ("no",  "n", "false", "f", "0", "0.0", "", "none", "[]", "{}"): return False
    raise Exception('Invalid value for boolean conversion: ' + str(value))


def check_xml_invalid(xml_path):
    ET.parse(xml_path)


'''
设置hosts
'''


def set_hosts(host_file):
    env.hosts = open(host_file, "r").readlines()


def backup_files(local_path, remote_path, use_glob=True):
    # Handle empty local path
    local_path = local_path or os.getcwd()

    # Test whether local_path is a path or a file-like object
    local_is_path = not (hasattr(local_path, 'read') \
        and callable(local_path.read))

    if local_is_path:
        # Apply lcwd, expand tildes, etc
        local_path = os.path.expanduser(local_path)
        local_path = apply_lcwd(local_path, env)
        if use_glob:
            # Glob local path
            names = glob(local_path)
        else:
            # Check if file exists first so ValueError gets raised
            if os.path.exists(local_path):
                names = [local_path]
            else:
                names = []
    else:
        names = [local_path]

    # 检查远程是目录还是文件
    root_path, extension = os.path.splitext(remote_path)

    for lpath in names:
        # 获取本地文件名
        local_file_name = os.path.basename(lpath)

        # 如果是目录
        if not extension:
            remote_dir, remote_file = root_path, local_file_name
        else:
            remote_dir, remote_file = os.path.split(remote_path)

        # 备份remote的文件
        with settings(warn_only=True):
            with cd(remote_dir):
                if run("test -f {0}".format(remote_file)).return_code == 0:
                    run("cp {0} {0}.backup.{1}".format(remote_file,
                                                       datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")))

'''
向远程主机push文件
'''


def push_file(local_path=None, remote_path=None, use_sudo=False,
              mirror_local_mode=False, mode=None, use_glob=True, temp_dir="", backup="true"):
    # 备份remote的文件
    if __to_bool(backup):
        backup_files(local_path=local_path, remote_path=remote_path, use_glob=use_glob)

    # push文件到远程主机
    put(local_path=local_path, remote_path=remote_path, use_sudo=use_sudo,
        mirror_local_mode=mirror_local_mode, mode=mode, use_glob=use_glob, temp_dir=temp_dir)



'''
Merge并推送配置文件到远程主机
'''


def merge_to_remote(local_xml_path, remote_xml_path, replace="true"):
    try:
        # 获取远程的主机host
        remote_host = env.host_string

        # 从远程主机下载文件到本地
        remote_xml_path_local_copy = "{0}.{1}".format(local_xml_path, remote_host)
        get(remote_xml_path, remote_xml_path_local_copy)

        # 执行文件的merge工作
        merged = append_xml_config(local_xml_path, remote_xml_path_local_copy, replace=replace)
        merged_file_path = "{0}.merged".format(remote_xml_path_local_copy)
        merged_file = open(merged_file_path, "w")
        merged_file.write(merged)
        merged_file.close()

        # check merge后的文件的合法性
        check_xml_invalid(merged_file_path)

        # 文件推送到远程主机
        push_file(merged_file_path, remote_xml_path)
    finally:
        # remove本地文件
        with settings(warn_only=True):
            local("rm {0}".format(remote_xml_path_local_copy))
            # 先check变量是否已经定义
            if 'merged_file_path' in locals():
                local("rm {0}".format(merged_file_path))


'''
回滚远程主机的配置文件
'''


def roll_back_remote_file(target_file_path, delete_after_roll="true"):
    # 检查目标文件是否存在
    run("test -f {0}".format(target_file_path))

    # 找出目标文件的最新备份
    remote_dir, remote_file = os.path.split(target_file_path)
    with cd(remote_dir):
        file_name = run("ls -t | grep {0} | grep backup | head -1".format(remote_file))

        user_answer = raw_input("Roll back {0} using {1}? yes/no :".format(remote_file, file_name))
        user_answer = user_answer.strip().lower()
        if user_answer == "yes" or user_answer == "y":
            # 回滚吧
            run("cp {0} {1}".format(file_name.strip(), remote_file))
            if __to_bool(delete_after_roll):
                # 回滚后删除备份文件
                run("rm {0}".format(file_name.strip()))


def append_xml_config(local_xml_path, remote_xml_path, replace="true"):
    # 当前的新增配置
    local_parser = etree.XMLParser(remove_comments=True, encoding="utf-8", remove_blank_text=True)
    local_xml_tree = etree.parse(local_xml_path, local_parser)
    local_xml_tree_root = local_xml_tree.getroot()

    # 远程的已有配置
    remote_parser = etree.XMLParser(attribute_defaults=True, load_dtd=True, strip_cdata=False,
                                    remove_comments=False, encoding="utf-8", remove_blank_text=True)
    remote_xml_tree = etree.parse(remote_xml_path, remote_parser)
    remote_xml_tree_root = remote_xml_tree.getroot()

    # 遍历新增配置项
    for conf_property in local_xml_tree_root.findall("property"):
        property_name = conf_property.find("name").text
        overwrite_exist = False
        for remote_conf_property in remote_xml_tree_root.findall("property"):
            # print etree.tostring(remote_conf_property, encoding="utf-8", pretty_print=True)

            remote_property_name = remote_conf_property.find("name").text
            # 远程存在相同的配置项并且允许覆盖
            if property_name == remote_property_name and __to_bool(replace):
                overwrite_exist = True

                remote_conf_property.find("value").text = conf_property.find("value").text

                # 设置description
                conf_property_desc = conf_property.find("description")
                if conf_property_desc is not None:
                    remote_conf_property_desc = remote_conf_property.find("description")
                    if remote_conf_property_desc is not None:
                        remote_conf_property.remove(remote_conf_property_desc)

                    # 需要clone不是直接引用
                    remote_conf_property.append(copy.deepcopy(conf_property_desc))

                    # print etree.tostring(remote_conf_property, encoding="utf-8", pretty_print=True)

        # 如果远程没有该配置项
        if not overwrite_exist:
            remote_xml_tree_root.append(copy.deepcopy(conf_property))

    return etree.tostring(remote_xml_tree, encoding="utf-8", pretty_print=True, xml_declaration=True)


'''
执行远程命令
'''


def execute_remote_cmd(cmd, remote_dir=""):
    if remote_dir:
        with cd(remote_dir):
            run(cmd)
    else:
        run(cmd)


'''
远程sed命令,替换为的内容由cmd_target命令生成
'''


def sed_use_cmd_output(source, cmd_target, remote_file):
    cmd_output = run(cmd_target)
    run("sed 's/{0}/{1}/g' {2}".format(source, cmd_output, remote_file))


if __name__ == "__main__":
    try:
        raise ArithmeticError()
    finally:
        print("always do")
    print "not here"