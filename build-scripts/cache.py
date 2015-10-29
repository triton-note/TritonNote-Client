#!/usr/bin/env python

import os
import sys
import tarfile

import boto3
import botocore
import shell

def getObject(name):
    s3 = boto3.resource('s3')
    folder = os.environ['PROJECT_REPO_SLUG']
    bucket = s3.Bucket(os.environ['AWS_S3_BUCKET'])
    filename = name + '.tar.bz2'
    return (bucket.Object(folder + "/" + filename), filename)

def load(name):
    (obj, filename) = getObject(name)
    print('Loading', obj, 'to', filename)
    shell.mkdirs(os.path.dirname(filename))
    file = open(filename, mode='wb')
    try:
        file.write(obj.get()['Body'].read())
        file.close()
        tar = tarfile.open(mode='r:bz2', name=filename)
        tar.extractall()
        tar.close()
    except botocore.exceptions.ClientError as e:
        error_code = int(e.response['Error']['Code'])
        if error_code == 404:
            print(name, 'is not saved')
        else:
            print(name, 'is failed to load:', error_code)
    finally:
        os.remove(filename)

def save(name):
    (obj, filename) = getObject(name)
    print('Saving', filename, 'to', obj)
    tar = tarfile.open(mode='w:bz2', name=filename)
    tar.add(name)
    tar.close()
    file = open(filename, mode='rb')
    try:
        obj.put(Body=file.read())
    except botocore.exceptions.ClientError as e:
        error_code = int(e.response['Error']['Code'])
        print(name, 'is failed to save:', error_code)
    finally:
        file.close()
        os.remove(filename)

if __name__ == "__main__":
    action = sys.argv[1]
    if len(sys.argv) < 3:
        list = ['node_modules']
    else:
        list = sys.argv[2:]

    print(action, list)
    for name in list:
        if action == "load":
            load(name)
        elif action == "save":
            save(name)
