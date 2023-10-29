# Package the mission! Run this from cmd.exe: 'python package.py <zipfile>'

# TODO: parse .misassemble file (here and in each subdir) for included/excluded
#       files. Something like:
#
#       filename        # include this file
#       +filename       # include this file, even if an earlier rule excluded it
#       -filename       # exclude this file, even if an earlier rule included it
#       subdir/filename # so you don't have to make a subdir/.misassemble if you don't want to
#       +subdir/filename
#       -subdir/filename
#       "filename with spaces"
#       "subdir with spaces/filename"
#       +"filename with spaces"
#       -"filename with spaces"
#       setting=value   # for configuring options (are there any?)
#       setting = value
#       ; comment
#       # comment
#       // comment
#       bare filename with spaces is an error
#       file+name? with symbols other than _ and non-leading - is an error
#       "filename =;# with other symbols, if you really have to"
#       [section]       # used for different profiles (default is called "default")
#       +[other]      # add all includes from [other] into this section
#       -[other]      # add all excludes from [other] into this section
#
#       *every* subdirectory in the tree that does not start with a . is
#       searched for .misassemble files. each such file applies only to its
#       subtree
#
#       additional options of any kind can be put on the command line, so
#       that overrides can be done or whatever.

# That way this script runs based on the configuration in the .mis and not have
# to be edited to work! And it can be packaged up with py2exe so others can use
# it.

# These files and directories will be included.
#
INCLUDE = [
    # Subdirs
    'books',
    'fam',
    'intrface',
    'mesh',
    'movies',
    'obj',
    'snd',
    'sq_scripts',
    'strings',
    'subtitles',

    # Files
    'fm.cfg',
    'newbridge.gam',
    'miss20.mis',
    'miss22.mis',
    'readme.txt',
    'readme_contest.txt',
    ]

# To exclude specific files from subdirs, put them here
#
EXCLUDE = [
    'sq_scripts\\testamb.nut',
    ]

def get_zipfile_name():
    import sys
    if len(sys.argv) < 2:
        raise ValueError("Missing zipfile argument!")
    name = sys.argv[1]
    if not name.lower().endswith('.zip'):
        name += '.zip'
    return name

def gather_files():
    from os import scandir
    from os.path import isdir
    def listdir_recursive(*paths):
        paths = set(paths)
        dirs = set(p for p in paths if isdir(p))
        files = paths - dirs
        while dirs:
            d = dirs.pop()
            for f in scandir(d):
                if f.is_dir():
                    dirs.add(f.path)
                else:
                    files.add(f.path)
        return files
    included_files = listdir_recursive(*INCLUDE)
    excluded_files = listdir_recursive(*EXCLUDE)
    return sorted(included_files - excluded_files)

def create_package(files, package_name):
    from os import replace
    from zipfile import ZipFile, ZIP_DEFLATED
    TEMP_PACKAGE = '.package.zip'
    with ZipFile(TEMP_PACKAGE, mode='w', compression=ZIP_DEFLATED) as zf:
        for f in files:
            print("> " + f)
            zf.write(f)
    replace(TEMP_PACKAGE, package_name)
    print(package_name + " created.")

if __name__ == '__main__':
    raise NotImplementedError("TODO: see big comment at the top")
    create_package(gather_files(), get_zipfile_name())
