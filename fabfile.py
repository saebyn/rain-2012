from fabric.api import local, lcd, env, settings
import fnmatch
import os
import os.path


env.build_dir = 'build'
env.aws_access_key_id = '1H82F3WVH8GA8WZR6WR2'
env.aws_secret_access_key = '3pr5Dq4lYWbji9LarUhEFgi+tHh5iJDa2EeuUE8V'


def watch(delay='5'):
    while True:
        local("inotifywait -r --exclude '^\..*\.swp$' --exclude '^.git/.*$' -e modify -e move -e create -e delete .")
        print 'Rebuilding'
        local("fab build")


def clean():
    local("rm -rf %(build_dir)s" % env)
    local("mkdir -p %(build_dir)s" % env)


def build():
    clean()

    # copy .txt files to build dir
    local("cp -r src/*.txt %(build_dir)s/" % env)

    # copy .css files to build dir
    local("cp -r src/css %(build_dir)s/" % env)

    # copy crossdomain.xml files to build dir
    local("cp -r src/crossdomain.xml %(build_dir)s/" % env)

    # build coffescript files
    local("coffee -c -o %(build_dir)s/js src/js/*.coffee" % env)

    # copy js libs
    local("cp -r src/js/lib %(build_dir)s/js/" % env)

    # build HAML files
    for file in os.listdir('src'):
        if fnmatch.fnmatch(file, '*.haml'):
            input_fn = os.path.join('src', file)
            output_fn = os.path.join(env.build_dir,
                                     file.replace('haml', 'html'))
            local("haml -f html5 %s > %s" % (input_fn, output_fn,))

    local("mkdir -p %(build_dir)s/assets" % env)

    # copy sprites to build/assets/sprites dir
    local("cp -r assets/sprites %(build_dir)s/assets/" % env)

    # build level files into build/assets dir
    for file in os.listdir('assets/levels'):
        if fnmatch.fnmatch(file, '*.yaml'):
            input_fn = os.path.join('assets', 'levels', file)
            output_fn = os.path.join(env.build_dir, 'assets',
                                     file.replace('yaml', 'json'))

            with settings(warn_only=True):
                local("./assets/levels/build.py %s > %s" % (input_fn, output_fn,))

def deploy(bucket='rain-dev.saebyn.info'):
    build()
    # copy build dir to S3
    pass


def preview():
    build()
    with lcd(env.build_dir):
        local("python -m SimpleHTTPServer")
