"""
add_toc_to_md recursively searches for md files in the "docs" directory
and adds table of content [TOC] handle into the files where the TOC is missing
"""

import os


# target only "docs" folder
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, '../docs'))
TOC = ["[TOC]", "[[_TOC_]]"]


def add_toc(file_path):
    """
    Checks if [TOC] or [[_TOC_]] is present in the file
    If not, adds the TOC as a first line
    """
    with open(file_path, 'r') as f:
        content = f.readlines()

    if not any(any(toc in line for toc in TOC) for line in content):
        content.insert(1, '\n**Table of Contents**\n\n' + TOC[0] + '\n')
        with open(file_path, 'w') as f:
            f.writelines(content)
        print(f"Updated {file_path}")


def search_dir_tree(root_dir):
    """
    Searches through the dir tree and calls add_toc on all md files where TOC is missing
    """
    for dir_path, _, files in os.walk(root_dir):
        for f in files:
            if f.endswith(".md"):
                file_path = os.path.abspath(os.path.join(dir_path, f))
                add_toc(file_path)

def main():
    search_dir_tree(ROOT_DIR)

if __name__ == "__main__":
    main()
