#!/usr/bin/env bash

function test_case()
{
    
    output=`/usr/local/hadoop/libexec/hadoop-restrict.sh fs -rm $1`
    if [ -z "$output" ];then
       echo "test case failed:"$1
       exit
    fi
    output=`/usr/local/hadoop/libexec/hadoop-restrict.sh dfs -rm $1`
    if [ -z "$output" ];then
       echo "test case failed:"$1
       exit
    fi
    output=`/usr/local/hadoop/libexec/hadoop-restrict.sh fs -rmr $1`
    if [ -z "$output" ];then
       echo "test case failed:"$1
       exit
    fi
    output=`/usr/local/hadoop/libexec/hadoop-restrict.sh dfs -rmr $1`
    if [ -z "$output" ];then
       echo "test case failed:"$1
       exit
    fi
    output=`/usr/local/hadoop/libexec/hadoop-restrict.sh fs -rm -r $1`
    if [ -z "$output" ];then
       echo "test case failed:"$1
       exit
    fi
    output=`/usr/local/hadoop/libexec/hadoop-restrict.sh dfs -rm -r $1`
    if [ -z "$output" ];then
       echo "test case failed:"$1
       exit
    fi
    echo $output
}

test_case "/"
test_case "//"

test_case "/aaa"
test_case "/aaa/"
test_case "/aaa/*"
test_case "/aaa//*"
test_case "//aaa//*"


test_case "/aaa/bbb"
test_case "/aaa/bbb/"
test_case "/aaa/bbb/*"
test_case "///aaa//bbb//*"
test_case "///aaa//*//*"
test_case "///aaa//*"

echo "All testcases passed!"
